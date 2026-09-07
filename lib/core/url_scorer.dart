import 'finding.dart';
import 'fuzzy.dart';
import 'parsed_url.dart';
import 'risk_level.dart';
import 'rule_data.dart';
import 'scan_result.dart';

/// Layer 4 of the ScanSafe architecture: the 22-rule additive URL risk engine.
///
/// Pure Dart with no plugin or platform dependency, so the same code runs on
/// Android, iOS, web, and in unit tests. Rules are independent and additive —
/// each one that fires contributes its weight to the total.
///
/// Ported rule-for-rule from `scansafe_prototype.py`. Where the Python and the
/// architecture document disagree, the Python implementation wins, because it
/// is what the published evaluation numbers were produced with.
class UrlScorer {
  UrlScorer({SimHashCache? simHashCache})
      : _simHashCache = simHashCache ?? SimHashCache();

  /// Session-scoped fingerprint store backing Rule 20.
  final SimHashCache _simHashCache;

  static final RegExp _ipPattern = RegExp(r'^\d{1,3}(\.\d{1,3}){3}(:\d+)?$');
  static final RegExp _doubleExtension = RegExp(r'\.\w{2,4}\.\w{2,4}$');
  static final RegExp _nonAlnum = RegExp(r'[^a-z0-9]');
  static final RegExp _nonAlpha = RegExp(r'[^a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');

  /// Score [urlString] and return the verdict with both display layers.
  ScanResult score(String urlString) => _score(urlString, depth: 0);

  ScanResult _score(String urlString, {required int depth}) {
    var score = 0;
    final findings = <Finding>[];

    void flag(int ruleId, String plain, String technical, int points) {
      score += points;
      findings.add(Finding(
        ruleId: ruleId,
        plain: plain,
        technical: technical,
        points: points,
      ));
    }

    // Normalise. The whole URL is lowercased first, exactly as the prototype
    // does, so every downstream rule sees the same casing.
    var lower = urlString.toLowerCase().trim();

    final blobWrapped = lower.startsWith('blob:');
    if (blobWrapped) {
      // blob: wraps an inner https URL (blob:https://host/uuid). Unwrap it so
      // the host and path rules still fire; Rule 14 keys off the flag.
      final inner = lower.substring(5);
      if (inner.startsWith('http')) lower = inner;
    } else if (!lower.startsWith('http') &&
        !dangerousSchemes.any((s) => lower.startsWith('$s:'))) {
      // Only bare domains get a scheme prepended — dangerous schemes must
      // reach the parser intact so Rule 14 can read them.
      lower = 'https://$lower';
    }

    final parsed = ParsedUrl.parse(lower);

    final host = parsed.netloc;
    final path = parsed.path;
    final query = parsed.query;
    final fullUrl = lower;

    // Allowlist bypass. The research write-up flags this as a methodological
    // weakness, so it stays deliberately small and is reported explicitly
    // rather than silently returning a clean verdict.
    if (allowlistedDomains.contains(host) ||
        allowlistedDomains.any((d) => host.endsWith('.$d'))) {
      return ScanResult(
        url: urlString,
        score: 0,
        level: RiskLevel.safe,
        scannedAt: DateTime.now(),
        findings: [
          Finding(
            ruleId: 0,
            plain:
                'Verified safe: this domain is on the verified-safe allowlist.',
            technical: 'Scoring bypassed because host "$host" is allowlisted. '
                'Allowlisting suppresses all 22 rules for this host.',
            points: 0,
          ),
        ],
      );
    }

    // Rule 1 — HTTP instead of HTTPS (+2).
    if (parsed.scheme == 'http') {
      flag(
        1,
        'This link uses HTTP, not HTTPS — anything you send is unencrypted.',
        'Rule 1: HTTP scheme detected. No transport encryption.',
        2,
      );
    }

    // Rule 2 — raw IP address as host (+3).
    if (_ipPattern.hasMatch(host)) {
      flag(
        2,
        'This link goes to a raw IP address — legitimate sites use domain names.',
        'Rule 2: Host is an IP address ($host), not a domain name.',
        3,
      );
    }

    final tld = host.contains('.') ? '.${host.split('.').last}' : '';

    // Rule 3 — high-abuse TLD (+2).
    if (suspiciousTlds.contains(tld)) {
      flag(
        3,
        'The domain ends in "$tld", a top-level domain commonly used for phishing.',
        'Rule 3: TLD "$tld" is in the high-abuse list.',
        2,
      );
    }

    // Rule 4 — elevated-risk ccTLD (+1).
    if (riskyCcTlds.contains(tld)) {
      flag(
        4,
        'The domain ends in "$tld", a country code with elevated phishing usage.',
        'Rule 4: ccTLD "$tld" has elevated phishing association.',
        1,
      );
    }

    // Rule 5 — excessive subdomain depth (+2).
    final parts = host.split('.');
    if (parts.length > 4) {
      flag(
        5,
        'This URL has an unusually long chain of subdomains — a phishing pattern.',
        'Rule 5: ${parts.length} subdomain levels detected (threshold: 4).',
        2,
      );
    }

    // Rule 6 — long path (+1).
    if (path.length > 50) {
      flag(
        6,
        'This link has an unusually long path, often used to bury the real destination.',
        'Rule 6: Path length ${path.length} chars > 50 threshold.',
        1,
      );
    }

    // Rule 7 — excessive query parameters (+1).
    final ampersands = '&'.allMatches(query).length;
    if (ampersands > 4) {
      flag(
        7,
        'This URL carries a lot of query parameters — a common obfuscation pattern.',
        'Rule 7: ${ampersands + 1} query parameters detected.',
        1,
      );
    }

    // Rule 8 — brand embedded outside the apex domain (+3).
    // docs.google.com is legitimate Google; google-login.xyz is not. The rule
    // only fires when the brand appears somewhere other than the apex label.
    final apex = apexDomain(host);
    final hostClean = host.replaceAll(_nonAlnum, '');
    final apexCleanR8 = apex.replaceAll(_nonAlnum, '');
    for (final brand in brandList) {
      final brandClean = brand.replaceAll(_nonAlnum, '');
      if (hostClean.contains(brandClean) && apexCleanR8 != brandClean) {
        flag(
          8,
          '"$brand" appears embedded in the domain — possible brand spoofing.',
          'Rule 8: Brand "$brand" detected in non-apex domain position.',
          3,
        );
        break;
      }
    }

    // Rule 9 — URL shortener (+2).
    final baseHost = host.replaceAll('www.', '');
    if (urlShorteners.contains(baseHost)) {
      flag(
        9,
        'This is a shortened URL — the real destination is hidden.',
        'Rule 9: URL shortener detected ($baseHost).',
        2,
      );
    }

    // Rule 10 — "@" before the query (+3).
    if (fullUrl.split('?').first.contains('@')) {
      flag(
        10,
        'This URL contains "@", which can hide the real destination behind text that looks safe.',
        'Rule 10: "@" character detected in URL path — credential-hiding technique.',
        3,
      );
    }

    // Rule 11 — punycode / IDN homograph (+3).
    if (host.contains('xn--')) {
      flag(
        11,
        'This URL uses special character encoding to visually mimic a legitimate domain.',
        'Rule 11: Punycode/IDN detected in host ($host).',
        3,
      );
    }

    // Rule 12 — double file extension in the path (+2).
    final doubleExt = _doubleExtension.firstMatch(path);
    if (doubleExt != null) {
      flag(
        12,
        'The path ends in a double file extension — a common malware distribution trick.',
        'Rule 12: Double extension detected in path: ${doubleExt.group(0)}.',
        2,
      );
    }

    // Rule 13 — redirect wrapper (+3, plus the inner URL's own score).
    // From the GSU case study: SafeLinks wrapping scored clean on every
    // structural rule because the malicious destination was inside the query.
    for (final pattern in redirectWrappers) {
      if (!pattern.hasMatch(host)) continue;
      final values = parsed.queryValues('url');
      final innerUrl = values.isEmpty ? null : values.first;
      flag(
        13,
        'This is a redirect wrapper (such as SafeLinks). The real destination is hidden inside it. '
        '${innerUrl != null ? 'Destination: $innerUrl' : 'The destination could not be extracted.'}',
        'Rule 13: Redirect wrapper matched "${pattern.pattern}". '
        '${innerUrl != null ? 'Extracted destination: $innerUrl' : 'Inner URL extraction failed.'}',
        3,
      );
      // Score the inner URL and fold its score in. Depth-capped so a wrapper
      // pointing at itself cannot recurse without bound.
      if (innerUrl != null && depth < 3) {
        final innerResult = _score(innerUrl, depth: depth + 1);
        score += innerResult.score;
        findings.add(Finding(
          ruleId: 13,
          plain: 'The hidden destination scored ${innerResult.score} '
              '(${innerResult.level.label}) on its own.',
          technical:
              'Rule 13 (recursive): inner URL scored ${innerResult.score} '
              '(${innerResult.level.label}): $innerUrl',
          points: innerResult.score,
        ));
      }
      break;
    }

    // Rule 14 — dangerous URI scheme (+6, which alone forces HIGH RISK).
    // blob: was added after a real GSU phishing case — blob URLs are
    // browser-generated in-memory references and never appear in a legitimate
    // QR code.
    final isDangerousScheme =
        dangerousSchemes.contains(parsed.scheme) || blobWrapped;
    if (isDangerousScheme) {
      final schemeName = blobWrapped ? 'blob' : parsed.scheme;
      final extra = blobWrapped
          ? ' Blob URLs never appear in legitimate QR codes — the real destination is hidden.'
          : '';
      flag(
        14,
        'This URL uses a dangerous scheme ("$schemeName") — very likely malicious.$extra',
        'Rule 14: Dangerous URI scheme "$schemeName" detected. Weight +6 forces HIGH RISK.',
        6,
      );
    }

    // Rule 15 — high consonant ratio, a domain-generation-algorithm signal (+1).
    final domainAlpha = parts.first.replaceAll(_nonAlpha, '');
    if (domainAlpha.length > 4) {
      const vowels = 'aeiou';
      final consonants =
          domainAlpha.split('').where((c) => !vowels.contains(c)).length;
      final ratio = consonants / domainAlpha.length;
      if (ratio > 0.75) {
        flag(
          15,
          'The domain name has an unusual letter pattern, typical of auto-generated domains.',
          'Rule 15: Consonant ratio ${ratio.toStringAsFixed(2)} > 0.75 in domain "$domainAlpha".',
          1,
        );
      }
    }

    // Rule 16 — numeric-heavy domain label (+1).
    final hostBase = parts.first;
    final digitCount = _digit.allMatches(hostBase).length;
    if (digitCount > 2) {
      flag(
        16,
        'The domain name contains several numbers — uncommon for legitimate sites.',
        'Rule 16: $digitCount digits in domain base "$hostBase".',
        1,
      );
    }

    // Rule 17 — credential-harvesting keyword in path or query (+2).
    final lowerPath = path.toLowerCase();
    final lowerQuery = query.toLowerCase();
    for (final keyword in badKeywords) {
      if (lowerPath.contains(keyword) || lowerQuery.contains(keyword)) {
        flag(
          17,
          'The URL contains "$keyword" — a word commonly used on phishing sign-in pages.',
          'Rule 17: High-risk keyword "$keyword" detected in path/query.',
          2,
        );
        break;
      }
    }

    // Rule 18 — heavy percent-encoding in the query (+1).
    final percentCount = '%'.allMatches(query).length;
    if (percentCount > 3) {
      flag(
        18,
        'The URL hides characters behind encoding in its query string.',
        'Rule 18: $percentCount percent-encoded chars in query — potential obfuscation.',
        1,
      );
    }

    // Rule 19 — LCS fuzzy typosquatting on the apex domain (+3).
    // Catches grarnbling.edu, paypa1.com, arnazon.com — all of which slip past
    // Rule 8 because they never contain the brand as a literal substring.
    final typo = detectTyposquatting(host);
    if (typo != null) {
      final percent = (typo.similarity * 100).toStringAsFixed(0);
      flag(
        19,
        'This domain closely resembles "${typo.brand}" ($percent% similar) — likely a typosquatting attempt.',
        'Rule 19 (LCS fuzzy): apex domain vs "${typo.brand}", LCS similarity = '
        '${typo.similarity.toStringAsFixed(3)} (threshold: $lcsThreshold).',
        3,
      );
    }

    // Rule 19b — brand impersonation in a path segment after homoglyph
    // normalisation. Catches /0ne-dr1ve, /paypa1, /g00gle. Reported under
    // rule id 19 to match the architecture document's numbering.
    final apexFor19b = apex.toLowerCase();
    final pathSegments =
        lowerPath.split('/').where((s) => s.length >= 4).toList();
    for (final segment in pathSegments) {
      final segNorm = normaliseHomoglyphs(segment.replaceAll(_nonAlnum, ''));
      for (final brand in brandList) {
        final brandClean = brand.toLowerCase().replaceAll(_nonAlnum, '');
        // onedrive.live.com/... is legitimate; wixsite.com/0ne-dr1ve is not.
        if (apexFor19b == brandClean) continue;
        final sim = lcsSimilarity(segNorm, brandClean);
        // Higher threshold than Rule 19: path segments are short, so noise
        // crosses 0.75 far more easily than a full domain label does.
        if (sim >= 0.80) {
          flag(
            19,
            'The URL path "/$segment" resembles "$brand" once look-alike characters are '
            'normalised (${(sim * 100).toStringAsFixed(0)}% similar) — brand impersonation in the path.',
            'Rule 19b (path LCS): "$segment" normalised to "$segNorm" vs "$brandClean", '
            'LCS similarity = ${sim.toStringAsFixed(3)}.',
            3,
          );
          break;
        }
      }
    }

    // Rule 20 — SimHash near-duplicate of a URL seen earlier this session (+2).
    final nearDuplicate = _simHashCache.checkNearDuplicate(urlString);
    if (nearDuplicate != null && nearDuplicate != urlString) {
      flag(
        20,
        'This URL is structurally almost identical to another one scanned this session — '
        'a pattern associated with evasion campaigns.',
        'Rule 20 (SimHash): Hamming distance <= $simHashThreshold bits vs previously seen URL: $nearDuplicate',
        2,
      );
    }

    // Rule 21 — urgency language (+2).
    final fullPathQuery = '$lowerPath?$lowerQuery';
    for (final keyword in urgencyKeywords) {
      if (fullPathQuery.contains(keyword)) {
        flag(
          21,
          'This URL contains urgency language ("$keyword") — a pressure tactic used in '
          'smishing and QR phishing.',
          'Rule 21: Urgency keyword "$keyword" detected in path/query.',
          2,
        );
        break;
      }
    }

    // Rule 22 — free hosting platform (+3).
    // Real GSU case: ivoryrobinson94.wixsite.com/0ne-dr1ve impersonating OneDrive.
    for (final platform in freeHostingPlatforms) {
      if (host.endsWith(platform) || host.contains('.$platform')) {
        flag(
          22,
          'This URL is hosted on a free website builder ($platform) — legitimate organisations '
          'do not host sign-in or authentication pages there.',
          'Rule 22: Free hosting platform detected: $platform. '
          'Common phishing vector — fast, anonymous, free account creation.',
          3,
        );
        break;
      }
    }

    return ScanResult(
      url: urlString,
      score: score,
      level: RiskLevel.fromScore(score),
      findings: findings,
      scannedAt: DateTime.now(),
    );
  }
}
