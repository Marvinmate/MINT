function stim_idx = detect_TMS_pulse(pulse_signal, Rate)

    % PARAMETERS
    Amp_Threshold = 2.5;      % A TMS pulse must be at least 2.5V to be detected (they are usually 5V)
    Min_Duration_ms = 3;      % Reject TMS pulses lasting less than 3ms (artefacts on Ch3)
    Max_Duration_ms = 10;     % Reject TMS pulses lasting more than 10ms (usually last 5ms)

    Min_Samples = round(Min_Duration_ms * Rate / 1000);
    Max_Samples = round(Max_Duration_ms * Rate / 1000);

    % Thresholding
    above = abs(pulse_signal) > Amp_Threshold;

    % Find contiguous segments
    d = diff([0; above; 0]);
    start_idx = find(d == 1);
    end_idx   = find(d == -1) - 1;

    stim_idx = NaN;

    for i = 1:length(start_idx)

        seg_start = start_idx(i);
        seg_end   = end_idx(i);
        seg_len   = seg_end - seg_start + 1;

        if seg_len <= Max_Samples
            if seg_len >= Min_Samples

                segment = pulse_signal(seg_start:seg_end);
                [~, peak_rel] = max(abs(segment));
                stim_idx = seg_start + peak_rel - 1;
    
                return;
            end
        end
    end
end