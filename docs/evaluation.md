# Evaluation

Measurements of the shipped Dart engine. Reproduce with the scripts in `tool/`,
run against the `scan-safe` virtualenv (which has OpenCV installed):

```bash
<scan-safe>/.venv/Scripts/python.exe tool/measure_false_positives.py
```

```bash
<scan-safe>/.venv/Scripts/python.exe tool/measure_detection.py
```

Last run: 2026-09-07.

## False-positive rate (TASK-039)

Corpus: 212 legitimate URLs in `tool/legitimate_domains.txt` — universities
(including HBCUs and Louisiana institutions), campus services, banking,
government, big tech, developer tooling, retail, media, travel, health, plus
realistic deep links with paths and query strings. Every one should score SAFE
(0–2). Anything scoring 3+ is a false positive: a real site the app would warn a
student about.

| Configuration | False positives | Rate |
|---|---|---|
| Baseline (published prototype) | 9 / 212 | 4.2% |
| **Shipped (drop `gram` from brand list)** | **5 / 212** | **2.4%** |

Target is under 5%. Both configurations clear it, but the baseline failures were
the worst possible ones: `grambling.edu` itself, `instagram.com`, and Microsoft's
real sign-in pages.

## Detection rate

Corpus: the 28-URL `data/phishing_corpus.txt` from the research repo — 25
malicious across three categories, 3 controls.

| Configuration | Flagged (≥3) | HIGH RISK (≥6) | Control FPs |
|---|---|---|---|
| Baseline | 23 / 25 (92.0%) | 14 / 25 (56.0%) | 0 / 3 |
| **Shipped** | **23 / 25 (92.0%)** | **14 / 25 (56.0%)** | **0 / 3** |

Detection is **completely unchanged**. Zero of the 25 malicious URLs shifted score.

## TASK-038 — the `grambling.edu` false positive

`https://grambling.edu` scored 4 (SUSPICIOUS) on the published engine. Two rules
fired:

- **Rule 8 (+3)** — the brand `gram` is a substring of `gramblingedu`, and the
  apex label `grambling` is not equal to `gram`, so the rule concluded a brand
  was embedded in a domain that does not own it.
- **Rule 15 (+1)** — `grambling` is 7 consonants out of 9 (0.778), over the 0.75
  domain-generation-algorithm threshold.

### Candidates evaluated

| Candidate | Change | FP rate | Detection impact |
|---|---|---|---|
| A | Remove `gram` from the brand list | 2.4% | None |
| B | Rule 15 threshold 0.75 → 0.80 | 4.2% | **Regression** |
| C | Both | 2.4% | **Regression** |

### Decision: Candidate A

`gram` was redundant with `grambling`, which is already in the brand list, and is
a substring of it — so the entry could only ever fire on the institution the
project is built at, and on `instagram.com`. Removing it is strictly dominant:
it halves the false-positive rate and changes no malicious score.

**Candidate B was rejected.** It bought no additional false-positive reduction —
Rule 15 contributes only +1, never enough to cross a verdict threshold on its own
— and it downgraded `https://grarnbling.edu/student/login` from HIGH RISK (6) to
SUSPICIOUS (5). That URL is a typosquat of the project's own university aimed at
its own students. Trading detection on the single most relevant attack in the
corpus for zero measured benefit is not a fix.

Both outcomes are locked in `test/url_scorer_test.dart` under
"TASK-038 regression guards".

## Remaining false positives

Five legitimate URLs still score 3 (SUSPICIOUS). All five are the same Rule 8
failure mode, and it is **not** the one TASK-038 fixed:

| URL | Why it fires |
|---|---|
| `https://outlook.office.com` | Brand `outlook` present, apex is `office` |
| `https://outlook.office.com/mail/inbox` | Same |
| `https://login.microsoftonline.com` | Brand `microsoft` present, apex is `microsoftonline` |
| `https://onedrive.live.com` | Brand `onedrive` present, apex is `live` |
| `https://gsumail.grambling.edu` | Brand `gsumail` present, apex is `grambling` |

Rule 8 asks "is this brand in a domain whose apex is not the brand?" and treats
the answer as evidence of spoofing. But large organisations legitimately host
brands on domains named after something else — `onedrive.live.com` really is
Microsoft, and `gsumail.grambling.edu` really is Grambling's student email.

This is a design limitation of the rule, not a bad list entry, so fixing it means
either a brand-to-parent-domain map (which is allowlisting, already flagged in the
research as a methodological weakness) or a genuinely better notion of domain
ownership. That is a research decision rather than a patch, so it is tracked as
**TASK-051** rather than being changed here.

The practical impact is bounded: these produce SUSPICIOUS, never HIGH RISK, and
the plain-English finding does name the actual pattern detected.

## Not yet measured

- **Decode-to-verdict latency** (TASK-040) — needs the camera path, which is
  Phase 2, and real Android hardware.
- **Scoring time in isolation** — expected well under the 10ms budget, since
  scoring is a pure function over a short string, but unmeasured.
