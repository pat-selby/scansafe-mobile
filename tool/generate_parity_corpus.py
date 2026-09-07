"""Generate ground-truth scores for the Dart parity tests.

The Dart engine must score identically to the Python research prototype, with
one exception: a small, explicit, measured set of divergences listed in
DIVERGENCES below. Those are applied to the prototype in memory here, so the
generated corpus describes the engine ScanSafe actually ships.

Nothing in the `scan-safe` repo is modified. Each divergence must carry a
reason and the measurement that justified it, so the parity contract stays a
statement about deliberate decisions rather than drift.

Usage (from scansafe-mobile, using the scan-safe venv):
    <scan-safe>/.venv/Scripts/python.exe tool/generate_parity_corpus.py > tool/parity_corpus.json
"""

import json
import re
import sys

sys.path.insert(0, r"C:/Users/patri/OneDrive/Documents/my-github-projects/scan-safe/scansafe")
import scansafe_prototype as sp  # noqa: E402

# --- Deliberate divergences from the published prototype -------------------
#
# TASK-038. Measured with tool/measure_false_positives.py (212 legitimate URLs)
# and tool/measure_detection.py (28-URL phishing corpus) on 2026-09-07.
#
# Dropping "gram" from the brand list:
#   false positives 4.2% -> 2.4%
#   detection       unchanged (0 of 25 malicious URLs changed score)
#
# "gram" was redundant with "grambling" and is a substring of it, so Rule 8
# fired on the project's own university and on instagram.com. A rejected
# alternative — raising Rule 15's consonant threshold from 0.75 to 0.80 —
# bought no further false-positive reduction and downgraded
# grarnbling.edu/student/login from HIGH RISK to SUSPICIOUS, which is exactly
# the attack class this project exists to catch.
DIVERGENCES = {
    "brand_list_remove": ["gram"],
}

sp.BRAND_LIST = [b for b in sp.BRAND_LIST if b not in DIVERGENCES["brand_list_remove"]]

CORPUS = [
    # One case per rule, in rule order.
    "https://google.com",
    "example.com",
    "http://example.com",
    "http://192.168.1.1/login",
    "https://free-gift.xyz",
    "https://news.ru",
    "https://a.b.c.d.e.example.com",
    "https://example.com/" + "seg/" * 20,
    "https://example.com/p?a=1&b=2&c=3&d=4&e=5&f=6",
    "https://paypal.fakesite.com",
    "https://bit.ly/3xAbCd",
    "https://example.com@evil.com/path",
    "https://xn--80ak6aa92e.com",
    "https://example.com/invoice.pdf.exe",
    "https://na01.safelinks.protection.outlook.com/?url=http%3A%2F%2Fevil.tk%2Flogin",
    "javascript:alert(1)",
    "blob:https://evil.com/2f8a-uuid",
    "data:text/html,hello",
    "https://xkcdvbnmqz.com",
    "https://abc123456.com",
    "https://example.com/login",
    "https://example.com/p?x=%41%42%43%44%45",
    "https://paypa1.com",
    "https://grarnbling.edu",
    "https://arnazon.com",
    "https://ivoryrobinson94.wixsite.com/0ne-dr1ve",
    "https://example.com/verify-now",
    "https://acm-grambling.github.io",
    "https://acm-grambling.github.io/events",
    "https://docs.google.com/document/d/abc",
    "https://grambling.edu",
    "https://secure-chase-login.tk/account/verify",
    "https://my.site.vercel.app/paypa1",
    "https://tinyurl.com/abcd",
    "http://10.0.0.5:8080/admin/password",
    "https://office365-login.click/auth?token=abc",

    # False-positive regressions guarded by TASK-038. These are real sites and
    # must stay SAFE (0-2) — a warning on any of them teaches students to
    # ignore warnings.
    "https://www.grambling.edu/admissions",
    "https://www.instagram.com",
    "https://www.grambling.edu/academics/colleges/college-of-business",

    # Detection regressions. The typosquat of the project's own university
    # must stay HIGH RISK — this is what the rejected Rule 15 change broke.
    "https://grarnbling.edu/student/login",
    "http://xn--pypal-4ve.xyz/signin/verify?action=urgent",
]

out = []
for url in CORPUS:
    sp._SIMHASH_CACHE.clear()
    result = sp.score_url(url)
    rules = sorted({
        int(m.group(1))
        for f in result.tech_findings
        for m in [re.match(r"Rule (\d+)", f)]
        if m
    })
    out.append({
        "url": url,
        "score": result.score,
        "level": result.level,
        "rules": rules,
    })

print(json.dumps(out, indent=2))
