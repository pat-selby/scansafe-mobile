# Parity corpus tooling

The Dart engine's acceptance criterion is that it scores identically to the original
Python research prototype. These scripts produce that evidence.

1. `generate_parity_corpus.py` imports `scansafe_prototype.py` from the `scan-safe`
   repo, scores every URL in its corpus with a freshly cleared SimHash cache, and
   writes `parity_corpus.json`.
2. `generate_parity_test.py` turns that JSON into `test/url_scorer_test.dart`.

Run them from the `scan-safe` virtualenv, which has OpenCV installed:

```bash
/path/to/scan-safe/.venv/Scripts/python.exe tool/generate_parity_corpus.py > tool/parity_corpus.json
python tool/generate_parity_test.py
```

Both scripts hold absolute paths to the `scan-safe` checkout — update them if the repo
moves.

Regenerate deliberately. If a parity test goes red, the engine has drifted from the
artefact the published numbers came from; regenerating the corpus to make it green
destroys the evidence rather than fixing the problem.
