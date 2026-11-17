# Maintenance tests

Tests use four [synthetic recordings](fixtures/README.md). Run them from
a writable directory outside the checkout. With Octave and its
`signal` and `io` packages installed:

```bash
octave-cli --quiet --no-history /path/to/MINT/tests/test_science.m
```

This exercises both sample rates, the MEP windows, TTL indices,
pre-stimulation QC, CSP methods, aggregation, and XLSX metadata repair.

With Python 3.10 or newer, Pillow, openpyxl, Nextflow and Docker:

```bash
python3 /path/to/MINT/tests/test_pipeline.py new-output-directory
```

The integration test runs standard and Slim modes at both rates. It
compares numeric exports, verifies PNG resolution and MultiQC, and
tests cache reuse after a file timestamp changes.
