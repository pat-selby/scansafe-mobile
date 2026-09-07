/// Static rule inputs, ported verbatim from `scansafe_prototype.py` so the
/// Dart engine scores identically to the Python research prototype.
library;

/// Known brand names for homoglyph / substitution detection (Rules 8, 19, 22).
const List<String> brandList = [
  'paypal', 'apple', 'microsoft', 'google', 'amazon', 'facebook',
  'instagram', 'twitter', 'netflix', 'chase', 'wellsfargo', 'bankofamerica',
  // 'gram' was removed (TASK-038). It was redundant with 'grambling' and a
  // substring of it, so Rule 8 fired on grambling.edu and instagram.com.
  // Measured: false positives 4.2% -> 2.4% across 212 legitimate URLs, with
  // zero change in detection across the 28-URL phishing corpus.
  'grambling', 'gsumail', 'outlook', 'office365',
  'onedrive', 'dropbox', 'sharepoint', 'docusign', 'zoom', 'webex',
];

/// Free hosting platforms abused for phishing (Rule 22). Attackers use these
/// because accounts are free, anonymous, and fast to create.
const Set<String> freeHostingPlatforms = {
  'wixsite.com', 'weebly.com', 'carrd.co', 'webflow.io',
  'github.io', 'gitlab.io', 'netlify.app', 'vercel.app',
  'pages.dev', 'firebaseapp.com', 'web.app', 'glitch.me',
  'replit.app', '000webhostapp.com', 'infinityfreeapp.com',
  'freewebhostingarea.com', 'byet.host',
};

/// Suspicious TLDs (Rule 3).
const Set<String> suspiciousTlds = {
  '.xyz', '.tk', '.ml', '.ga', '.cf', '.gq', '.top', '.club',
  '.online', '.site', '.link', '.click', '.download', '.zip',
};

/// High-risk ccTLDs sometimes abused (Rule 4).
const Set<String> riskyCcTlds = {'.ru', '.cn', '.pw', '.cc', '.su'};

/// Common URL shorteners (Rule 9).
const Set<String> urlShorteners = {
  'bit.ly', 'tinyurl.com', 't.co', 'ow.ly', 'goo.gl', 'tiny.cc',
  'is.gd', 'buff.ly', 'rebrand.ly', 'short.io', 'cutt.ly',
};

/// SafeLinks / redirect wrapper patterns (Rule 13 — GSU phishing case study).
final List<RegExp> redirectWrappers = [
  RegExp(r'safelinks\.protection\.outlook\.com'),
  RegExp(r'urldefense\.proofpoint\.com'),
  RegExp(r'urldefense\.com'),
  RegExp(r'protect-us\.mimecast\.com'),
  RegExp(r'protect2\.fireeye\.com'),
  RegExp(r'na01\.safelinks\.protection\.outlook\.com'),
];

/// Verified safe domains / subdomains, to prevent false positives on trusted
/// hosts. The research write-up flags allowlisting as a methodological
/// weakness — keep this set minimal and justified.
const Set<String> allowlistedDomains = {
  'acm-grambling.github.io',
};

/// Known-bad keywords in path/query (Rule 17).
const List<String> badKeywords = [
  'login', 'signin', 'verify', 'update', 'secure',
  'account', 'banking', 'confirm', 'password', 'auth',
];

/// Urgency language (Rule 21) — smishing / quishing pressure tactics.
const List<String> urgencyKeywords = [
  'urgent', 'immediately', 'act-now', 'act_now', 'expires',
  'suspended', 'limited-time', 'winner', 'prize', 'claim-now',
  'claim_now', 'verify-now', 'verify_now', 'alert', 'warning',
  'blocked', 'unusual-activity', 'unusual_activity',
];

/// Dangerous URI schemes (Rule 14).
const Set<String> dangerousSchemes = {'data', 'javascript', 'vbscript'};

/// Second-level labels that form two-part TLDs (e.g. `.co.uk`, `.com.au`).
const Set<String> knownSlds = {
  'co', 'com', 'net', 'org', 'gov', 'edu', 'ac', 'me', 'ne', 'or',
};

/// Homoglyph normalisation for Rule 19b.
///
/// Mirrors the Python `str.maketrans("013456789@!$", "oieasgbtbgas")`
/// character-for-character.
const Map<String, String> homoglyphMap = {
  '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '6': 'g',
  '7': 'b', '8': 't', '9': 'b', '@': 'g', '!': 'a', r'$': 's',
};
