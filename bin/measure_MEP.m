function [amp, onset_idx, offset_idx, flag] = ...
        measure_MEP(signal, search_start, search_end, Rate, Sec)

% MEASURE_MEP
%   Detects a motor-evoked potential in a single-channel EMG signal.
%
%   Strategy (borrowed from Calculate_MEP.m):
%     1. Work with the signal differential to ignore slow drifts.
%     2. Savitzky-Golay filter to remove noise spikes.
%     3. Find the sample with the largest absolute differential in the
%        search window → centre of MEP.
%     4. Amplitude = peak-to-peak over ±Sec seconds around centre.
%
%   Inputs:
%     signal       - full trial EMG (samples × 1)
%     search_start - first sample of MEP search window
%     search_end   - last  sample of MEP search window
%     Rate         - sampling rate (Hz)
%     Sec          - half-window (s) for amplitude calculation
%
%   Outputs:
%     amp        - peak-to-peak amplitude (V)
%     onset_idx  - sample index of MEP centre (NaN if not found)
%     offset_idx - last sample of amplitude window (NaN if not found)
%     flag       - "Valid" | "No MEP Detected"

    amp        = NaN;
    onset_idx  = NaN;
    offset_idx = NaN;
    flag       = "No MEP Detected";

    % Guard against out-of-range windows
    search_start = max(search_start, 2);             % need at least 1 sample before for diff
    search_end   = min(search_end,   length(signal));

    if search_start >= search_end
        return;
    end


    %% Find MEP Amplitude
    % --- Extract search segment ---
    segment = signal(search_start:search_end);
    
    if isempty(segment) || all(isnan(segment))
        return;
    end
    
    [~, peak_idx] = max(abs(segment));
    centre_idx = search_start + peak_idx - 1;


    % Amplitude window (±Sec around centre, clamped to trial bounds)
    win_start = max(centre_idx - round(Sec * Rate), 1);
    win_end   = min(centre_idx + round(Sec * Rate), length(signal));

    if win_start >= win_end
        return;
    end

    % Add minimum amplitude for MEP detection
    Min_MEP_Amplitude = 0.00005; % 50 µV (adjust based on your data scale)

    amp = max(signal(win_start:win_end)) - min(signal(win_start:win_end));

        Min_MEP_Amplitude = 0.00005; % 50 µV
        
        if amp < Min_MEP_Amplitude
            onset_idx  = NaN;
            offset_idx = NaN;
            flag       = "No MEP Detected";
        else
            onset_idx  = centre_idx;
            offset_idx = win_end;
            flag       = "Valid";
        end

end

