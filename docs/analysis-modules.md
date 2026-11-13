# Analysis modules

MINT implements the historical acquisition and measurement methods described below. Timing and window sizes refer to the required sample rate of 4,000 Hz. The source functions are in [the Octave library](https://github.com/Marvinmate/MINT/tree/main/bin), and the configurable values are in [the scientific parameters](https://github.com/Marvinmate/MINT/blob/main/assets/scientific_params.json).

## Motor evoked potentials (MEP)

A motor evoked potential is the EMG response elicited by TMS. MINT reports its peak-to-peak amplitude, calculated as the maximum minus the minimum in the measurement window. The input signal is in volts and the tables report amplitudes in millivolts.

- **CSP protocol:** MINT differentiates the trial EMG, applies a Savitzky–Golay filter, and uses the largest positive change in the expected interval (trial indices 450–650) to locate the measurement centre. It measures the raw EMG within ±10 ms of that centre.
- **IHI protocol:** MINT finds the largest absolute EMG deflection 12–60 ms after the corresponding pulse, then measures the peak-to-peak amplitude within ±10 ms, clipped to the trial boundaries. The right channel uses the test pulse. The left channel is measured for IHI10 and IHI40 trials using the conditioning pulse, with the historical 60 Hz correction enabled by default.

For IHI-protocol MEPs below 50 µV, the finite amplitude is retained and the measurement markers are unset. The trial-level MEP table reports the right-channel status as `No MEP Detected` in these cases.

## Cortical silent period (CSP)

The cortical silent period is the period of suppressed voluntary EMG following TMS. In MINT, the positive raw EMG peak within the MEP window defines the start of the measured interval. The offset search starts 120 samples (30 ms) after that peak.

CSP v2 estimates the baseline standard deviation from the smoothed first difference of the EMG, using the interval 280 to 80 samples before the MEP window. Starting at the offset search point, it checks the standard deviation in successive 21-sample windows. The first window above 25% of the baseline standard deviation supplies the initial offset.

A brief resumption of EMG can occur within the silent period. The method flags a possible **breakthrough** when a run of consecutive below-threshold windows resumes within 160 samples (40 ms) of the initial offset and spans 60 sample intervals (15 ms). If a subsequent threshold crossing is found, it replaces the initial offset. The duration is the time from the MEP peak to the resulting offset, exported in milliseconds. An offset at the first search sample yields a missing duration.

The per-recording table retains both historical method variants. The aggregate export uses v2 and includes baseline-normalized CSP and MEP values. The baseline is the mean of the non-missing T0 trials for the same participant and experimental condition. T0 is set to 100% in the normalized columns. At later time points, normalization requires a usable T0 baseline.

The measured duration depends on the EMG baseline, the selected peak, and the offset rule. Check the trial signal and the breakthrough flag when reviewing ambiguous offsets. A trial without a usable threshold crossing can fail during the historical endpoint calculation.

## Interhemispheric inhibition (IHI)

The IHI protocol pairs a conditioning pulse with a test pulse. MINT detects the two events on their dedicated channels. For each channel it takes the first contiguous segment whose absolute voltage exceeds 2.5 V for 3–10 ms, and uses its absolute peak as the event time. The interstimulus interval (ISI) is the absolute difference between the two event times in milliseconds.

| Exported class | Rule |
| --- | --- |
| `IHI_10ms` (IHI10) | ISI from 5 to 15 ms, inclusive. |
| `IHI_40ms` (IHI40) | ISI from 35 to 45 ms, inclusive. |
| `Unconditioned_MEP` | A test pulse is detected and no conditioning pulse is detected. |
| `Unknown` | Both pulses are detected and the ISI is outside the two ranges. |

A missing test pulse makes the recording fail. The classes describe stimulus timing, and the amplitude columns contain per-channel MEP measurements. To quantify inhibition, define a conditioned-to-unconditioned comparison appropriate to your study design. MINT exports the trial values used for that analysis.
