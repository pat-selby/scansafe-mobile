"""Measure the engine's false-positive rate on legitimate domains (TASK-039).

Every URL in `legitimate_domains.txt` should score SAFE (0-2). Anything scoring
3+ is a false positive: a real site the app would warn a student about.

The script imports the Python research prototype read-only and A/B tests fix
candidates by patching module state in memory. It never writes to the
`scan-safe` repo.

Usage (from the scansafe-mobile directory, using the scan-safe venv):
    <scan-safe>/.venv/Scripts/python.exe tool/measure_false_positives.py
"""

import os
import re
import sys

PROTOTYPE_DIR = r"C:/Users/patri/OneDrive/Documents/my-github-projects/scan-safe/scansafe"
sys.path.insert(0, PROTOTYPE_DIR)

import scansafe_prototype as sp  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
CORPUS = os.path.join(HERE, "legitimate_domains.txt")

VOWELS = "aeiou"


def load_corpus():
    urls = []
    with open(CORPUS, encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line and not line.startswith("#"):
                urls.append(line)
    return urls


def consonant_ratio(url):
    """Recompute Rule 15's input: consonant ratio of the first host label.

    Rule 15 contributes exactly +1 and is independent of every other rule, so
    knowing whether it fires lets us model a threshold change by arithmetic
    instead of forking the prototype.
    """
    lower = url.lower().strip()
    if not lower.startswith("http"):
        lower = "https://" + lower
    host = lower.split("//", 1)[-1].split("/", 1)[0]
    alpha = re.sub(r"[^a-z]", "", host.split(".")[0])
    if len(alpha) <= 4:
        return None
    consonants = sum(1 for c in alpha if c not in VOWELS)
    return consonants / len(alpha)


def score(url):
    sp._SIMHASH_CACHE.clear()
    result = sp.score_url(url)
    rules = sorted({
        int(m.group(1))
        for f in result.tech_findings
        for m in [re.match(r"Rule (\d+)", f)]
        if m
    })
    return result.score, rules


def evaluate(urls, *, drop_gram, rule15_threshold):
    """Return (false_positives, per-url scores) under a candidate config."""
    original = list(sp.BRAND_LIST)
    if drop_gram:
        sp.BRAND_LIST = [b for b in original if b != "gram"]

    try:
        rows = []
        for url in urls:
            raw, rules = score(url)
            adjusted = raw
            # Model a raised Rule 15 threshold: if it fired at 0.75 but would
            # not fire at the candidate threshold, remove its +1.
            if 15 in rules:
                ratio = consonant_ratio(url)
                if ratio is not None and not ratio > rule15_threshold:
                    adjusted -= 1
                    rules = [r for r in rules if r != 15]
            rows.append((url, adjusted, rules))
    finally:
        sp.BRAND_LIST = original

    fps = [r for r in rows if r[1] >= 3]
    return fps, rows


def report(name, urls, *, drop_gram, rule15_threshold):
    fps, rows = evaluate(urls, drop_gram=drop_gram, rule15_threshold=rule15_threshold)
    rate = len(fps) / len(urls) * 100
    noisy = [r for r in rows if r[1] > 0]

    print(f"\n{'=' * 72}")
    print(f"{name}")
    print(f"{'=' * 72}")
    print(f"  False positives (score >= 3): {len(fps)}/{len(urls)}  ({rate:.1f}%)")
    print(f"  Non-zero scores (any finding): {len(noisy)}/{len(urls)}")

    if fps:
        print("\n  Sites the app would warn about:")
        for url, sc, rules in sorted(fps, key=lambda r: -r[1]):
            print(f"    {sc:>2}  rules {str(rules):<18} {url}")

    # Rule frequency across everything that scored above zero.
    freq = {}
    for _, sc, rules in noisy:
        for r in rules:
            freq[r] = freq.get(r, 0) + 1
    if freq:
        print("\n  Rules firing on legitimate domains:")
        for rule, count in sorted(freq.items(), key=lambda kv: -kv[1]):
            print(f"    Rule {rule:<3} {count:>3} hits")

    return rate, fps


def main():
    urls = load_corpus()
    print(f"Corpus: {len(urls)} legitimate URLs")

    base_rate, base_fps = report(
        "BASELINE — current engine", urls, drop_gram=False, rule15_threshold=0.75
    )
    a_rate, _ = report(
        "CANDIDATE A — drop 'gram' from the brand list",
        urls, drop_gram=True, rule15_threshold=0.75,
    )
    b_rate, _ = report(
        "CANDIDATE B — Rule 15 consonant threshold 0.75 -> 0.80",
        urls, drop_gram=False, rule15_threshold=0.80,
    )
    c_rate, _ = report(
        "CANDIDATE C — both fixes", urls, drop_gram=True, rule15_threshold=0.80
    )

    print(f"\n{'=' * 72}")
    print("SUMMARY (false-positive rate, target < 5%)")
    print(f"{'=' * 72}")
    for name, rate in [
        ("baseline    ", base_rate),
        ("A: no 'gram'", a_rate),
        ("B: rule 15  ", b_rate),
        ("C: both     ", c_rate),
    ]:
        print(f"  {name}  {rate:5.1f}%")


if __name__ == "__main__":
    main()
