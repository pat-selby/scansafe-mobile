"""Check that false-positive fixes do not weaken real detection.

Runs the phishing corpus from the research repo through the same candidate
configurations as measure_false_positives.py. A fix that lowers the
false-positive rate by blinding the engine is not a fix.
"""

import os
import re
import sys

PROTOTYPE_DIR = r"C:/Users/patri/OneDrive/Documents/my-github-projects/scan-safe/scansafe"
sys.path.insert(0, PROTOTYPE_DIR)
import scansafe_prototype as sp  # noqa: E402

CORPUS = os.path.join(PROTOTYPE_DIR, "data", "phishing_corpus.txt")
VOWELS = "aeiou"


def load():
    """Return [(url, category)] where category is the A/B/C/D section letter."""
    entries, category = [], "?"
    with open(CORPUS, encoding="utf-8") as handle:
        for line in handle:
            stripped = line.strip()
            m = re.search(r"Category ([A-D])", stripped)
            if m:
                category = m.group(1)
                continue
            if not stripped or stripped.startswith("#"):
                continue
            url = stripped.split(" #")[0].strip()
            if url:
                entries.append((url, category))
    return entries


def consonant_ratio(url):
    lower = url.lower().strip()
    if not lower.startswith("http"):
        lower = "https://" + lower
    host = lower.split("//", 1)[-1].split("/", 1)[0]
    alpha = re.sub(r"[^a-z]", "", host.split(".")[0])
    if len(alpha) <= 4:
        return None
    return sum(1 for c in alpha if c not in VOWELS) / len(alpha)


def evaluate(entries, *, drop_gram, rule15_threshold):
    original = list(sp.BRAND_LIST)
    if drop_gram:
        sp.BRAND_LIST = [b for b in original if b != "gram"]
    try:
        rows = []
        for url, category in entries:
            sp._SIMHASH_CACHE.clear()
            result = sp.score_url(url)
            rules = {
                int(m.group(1))
                for f in result.tech_findings
                for m in [re.match(r"Rule (\d+)", f)]
                if m
            }
            score = result.score
            if 15 in rules:
                ratio = consonant_ratio(url)
                if ratio is not None and not ratio > rule15_threshold:
                    score -= 1
            rows.append((url, category, score))
    finally:
        sp.BRAND_LIST = original
    return rows


def report(name, entries, **cfg):
    rows = evaluate(entries, **cfg)
    malicious = [r for r in rows if r[1] in ("A", "B", "C")]
    controls = [r for r in rows if r[1] == "D"]

    flagged = [r for r in malicious if r[2] >= 3]
    high = [r for r in malicious if r[2] >= 6]
    control_fp = [r for r in controls if r[2] >= 3]

    print(f"\n{name}")
    print(f"  Malicious flagged (>=3):   {len(flagged)}/{len(malicious)}"
          f"  ({len(flagged) / len(malicious) * 100:.1f}%)")
    print(f"  Malicious HIGH RISK (>=6): {len(high)}/{len(malicious)}"
          f"  ({len(high) / len(malicious) * 100:.1f}%)")
    print(f"  Control-group FPs:         {len(control_fp)}/{len(controls)}")
    return {r[0]: r[2] for r in rows}


def main():
    entries = load()
    print(f"Phishing corpus: {len(entries)} URLs "
          f"({sum(1 for _, c in entries if c != 'D')} malicious, "
          f"{sum(1 for _, c in entries if c == 'D')} control)")

    base = report("BASELINE", entries, drop_gram=False, rule15_threshold=0.75)
    cand = report("CANDIDATE C (drop 'gram' + Rule 15 at 0.80)",
                  entries, drop_gram=True, rule15_threshold=0.80)

    changed = {u: (base[u], cand[u]) for u in base if base[u] != cand[u]}
    print(f"\n  URLs whose score changed: {len(changed)}")
    for url, (before, after) in changed.items():
        verdict_before = sp.RiskLevel.from_score(before)
        verdict_after = sp.RiskLevel.from_score(after)
        flag = "  <-- VERDICT CHANGED" if verdict_before != verdict_after else ""
        print(f"    {before} -> {after}  ({verdict_before} -> {verdict_after}){flag}")
        print(f"        {url}")


if __name__ == "__main__":
    main()
