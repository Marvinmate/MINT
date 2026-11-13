# Input data

MINT reads LabChart MATLAB exports. Point `--input` to the directory containing the protocol folders.

```text
input/
├── CSP/
│   └── sub-XX/
│       ├── Full/
│       │   ├── CSP_T0.mat
│       │   ├── CSP_T1.mat
│       │   ├── CSP_T2.mat
│       │   ├── CSP_T3.mat
│       │   ├── CSP_T4.mat
│       │   └── CSP_T5.mat
│       ├── Half/
│       │   └── …
│       └── Pbo/
│           └── …
└── IHI/
    └── sub-XX/
        └── Full/
            ├── IHI_T0.mat
            ├── IHI_T1.mat
            ├── IHI_T2.mat
            ├── IHI_T3.mat
            ├── IHI_T4.mat
            └── IHI_T5.mat
```

Use the exact protocol names `CSP` and `IHI`, and the exact condition names `Full`, `Half`, and `Pbo` for the corresponding full, half, and placebo experimental conditions. MINT uses these as labels. Each file represents one time point, `T0` through `T5`; `T0` is the baseline for CSP normalization. The protocol in the file name must match the top-level folder.

Participant IDs can use ASCII letters, digits, underscores, and hyphens. The prefix `sub-` is optional and removed on import. Do not supply both forms of the same ID for the same protocol, condition, and time point. Legacy layouts may contain `Données_CSP` directly inside `CSP`, or `Données_IHI` directly inside `IHI`, before the participant folders.

For each participant, protocol, and condition present in the input, MINT normally requires all six time points. Use `--strict_timepoints false` for an intentionally incomplete series and review `missing_recordings.tsv` afterward. The protocol folders you need depend on the [selected modules](running-mint.md#select-modules).

## LabChart MAT requirements

| Field | Expected content |
| --- | --- |
| `data` | Concatenated signal samples, as finite numeric values. |
| `datastart`, `dataend` | One-based, inclusive sample indices within `data`, as exported by LabChart. Each channel block must span 1,600 samples per trial. |
| `samplerate` | 4,000 Hz throughout the recording. |
| `unittext` | Signal units in volts, labeled `V`. |
| `titles` | LabChart channel titles. MINT uses channel position to identify the signals. |

- **CSP recordings** contain one EMG channel.
- **IHI recordings** contain four channels in order: right EMG, left EMG, test pulse, conditioning pulse. The concatenated data start at index 1 and store the four channel blocks for each trial consecutively. Each trial must have a detectable test pulse. An absent conditioning pulse is valid for an unconditioned trial.

A MAT file that opens in MATLAB can still have the wrong layout, sample rate, units, or channel order for MINT.
