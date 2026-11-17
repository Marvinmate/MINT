# Validation and limitations

| Check | Scope |
| --- | --- |
| Historical comparison at 4,000 Hz | 108 recordings covering 3,758 trials. V2 was compared against archived V1 trial measurements, classifications, missing values and scientific tables. Left-channel IHI rounding differences across environments disappeared when V1 was replayed in the same Docker image. |
| Synthetic recordings at 1,000 and 4,000 Hz | Independently generated signals exercised rate-dependent windows, CSP endpoint selection, IHI indices, QC status and aggregation. |
| Workstation Docker integration | Full MEP, CSP and IHI runs, Slim and standard comparisons on synthetic data, PNG output at 300 dpi, numeric exports, and MultiQC. |
| Apptainer and Slurm | Profile resolution can be checked locally. Container conversion, mounts, submission, and cache reuse on the target cluster require an HPC run. |

**The 1,000 Hz evidence is synthetic only.** No real acquisition at that
rate was used to establish physiological accuracy. The cubic filter
requires at least five points, making its effective span 4 ms at 1,000 Hz
compared with 2.5 ms at 4,000 Hz. Check the recorded sample rate, effective
filter span and timing resolution when interpreting results from a
different acquisition.

MINT v0.2.0 was tested with GNU Octave. The container image records the
scientific runtime. There was no MATLAB validation for this release.

The historical IHI calculation uses the maximum absolute value within
the detected TTL segment. TTL onset, peak and end may differ. Preserve
the peak-based reference when comparing with historical analyses.
