# Scientific parameters

Copy [the default JSON](https://github.com/Marvinmate/MINT/blob/v0.2.0/assets/scientific_params.json)
and pass your copy with `--scientific_params study.json`. Provenance
records the effective parameters, sample rate, trial length and
smoothing span for each recording.

| Parameter | Default | Meaning |
| --- | --- | --- |
| `condition_order` | `[]` | Discover condition labels and use a stable order. An explicit order must include all observed conditions. |
| `mep_search_start_ms`, `mep_search_end_ms` | 12, 60 | Inclusive IHI search bounds relative to the corresponding TTL peak. The upper bound is clipped to the trial. |
| `mep_half_window_seconds` | 0.01 | Half-width of the peak-to-peak measurement window. The default is ±10 ms around the selected centre. |
| `remove_60hz` | `true` | Historical sine/cosine regression on left-channel IHI EMG. |
| `csp_end_method` | `breakthrough-aware` | Historical CSP v2 with breakthrough adjustment. Use `standard` for the first threshold crossing without breakthrough adjustment, as described in [Analysis modules](analysis-modules.md#cortical-silent-period-csp). |
| `sgolay_order`, `sgolay_span_ms` | 3, 2.5 | Order and requested span of the filter applied to the differentiated CSP signal. |
| `prestim_qc_enabled` | `false` | Measure and flag pre-stimulation EMG. |
| `prestim_start_ms`, `prestim_end_ms` | −50, −5 | Inclusive QC bounds relative to the QC reference. The start must precede the end, and both must be before the reference. |
| `prestim_threshold_uv` | 50 | Amplitude threshold in µV. QC flags a trial above this value. |
| `prestim_qc_exclude` | `false` | Exclude flagged trials from aggregate measurements when QC is enabled. |
| `csp_stimulus_time_ms` | `null` | Stimulation time within the CSP trial for QC. Supply it from the acquisition protocol. |

For example, set the following fields in your copied JSON to use a
different IHI search window, run QC in flag-only mode, and use the
standard CSP endpoint. Choose bounds and thresholds for your acquisition
rather than copying these example values into an analysis protocol.

```json
{
  "mep_search_start_ms": 20,
  "mep_search_end_ms": 45,
  "prestim_qc_enabled": true,
  "prestim_qc_exclude": false,
  "csp_end_method": "standard"
}
```

The example shows only the fields to edit. Keep the other default fields
in the file.

## Sampling and indices

MINT reads `samplerate` from each MAT file. The historical fields below
remain calibrated in samples at **4,000 Hz**. MINT scales them to the
actual sample rate. `rate: 4000` and `samples_per_trial: 1600` in the
default JSON describe the historical calibration. The values in the
MAT determine the rate and lengths used by the pipeline.

| Historical parameter | Default | Physical meaning |
| --- | --- | --- |
| `expect_mep_start`, `expect_mep_end` | 450, 650 | One-based CSP derivative search indices, corresponding to 112.25–162.25 ms from trial start at 4,000 Hz. |
| `csp_offset_samples` | 120 | Wait 30 ms after the MEP peak before searching for an offset. |
| `baseline_offset_samples` | 80 | Baseline ends 20 ms before the MEP window starts. |
| `baseline_duration_samples` | 200 | Historical baseline spans 50 ms. |
| `sliding_samples` | 20 | Rolling window spans 5 ms. |
| `silence_samples` | 60 | Below-threshold run spans 15 ms. |
| `breakthrough_max_samples` | 160 | A breakthrough can last at most 40 ms under the historical rule. |
| `threshold_fraction` | 0.25 | Fraction of baseline variability used to detect CSP offset. |

For a local one-based index `i`, the time is `(i-1)*1000/Fs` ms.
CSP scientific indices refer to the concatenated recording. IHI and
pre-stimulation QC indices refer to the trial. Relative millisecond
offsets are converted using `round(ms*Fs/1000)`. Both ends of a window
are counted, so a 5 ms span includes 21 points at 4,000 Hz and six
at 1,000 Hz.

The cubic Savitzky–Golay filter uses 11 points at 4,000 Hz. At 1,000 Hz,
the minimum valid five-point filter spans **4 ms**. MINT warns when the
effective span differs and records it in provenance.
[Validation and limitations](validation.md).

## Pre-stimulation EMG quality control

QC measures raw peak-to-peak EMG in µV within the configured window.
For IHI, MINT stores each channel value and flags the trial if either
exceeds the threshold. The QC reference is the earliest **onset** of a
detected TTL segment. The **peak** still defines stimulation timing
for MEP and IHI calculations and stimulus lines in figures.

A CSP recording has no TTL channel. Specify `csp_stimulus_time_ms` to
use CSP QC. Otherwise, QC reports `MissingReference`. Choose a suitable
threshold for studies with voluntary contraction. The default
pre-stimulation threshold is separate from the historical 50 µV IHI
MEP detection rule.

Trial QC states include `Disabled`, `Pass`, `AboveThreshold`,
`MissingReference`, `UnavailableWindow` and `MissingSignal`. Missing
measurements remain `NA`. MINT keeps detailed trial values and
`Included` flags when exclusion is enabled. Excluded trials are left
out of aggregate values, T0 normalization and MultiQC measurement
summaries.
