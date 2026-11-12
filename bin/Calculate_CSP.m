function [Duration_in_Sec,Idx_Peak,CSP_Offset] = Calculate_CSP(data,Rate,start_end,window_MEP,Offset_Assess_CSP,Offset_Assess_Baseline,Bsln_Dur,Length_Sliding,Fraction_Of_Threshold)

% Where to look to calculate baseline variance
Window_Baseline = window_MEP(1)-Offset_Assess_Baseline-Bsln_Dur:window_MEP(1)-Offset_Assess_Baseline;

diff_data = diff(data); % We'll work with the data differential to avoid possible slow drifts
diff_data = sgolayfilt(diff_data,3,11); % Smooth out the imperfections

% Calculate the threshold based on diff_data (not the raw data)
Threshold = std(diff_data(Window_Baseline))*Fraction_Of_Threshold; % That's our threshold to determine CSP offset

% Find positive MEP peak in the non-differentiated (original) data
Idx_Peak = find(max(data(window_MEP)) == data(start_end));
Idx_Peak = Idx_Peak(1) + start_end(1)-1; % Must be realigned with original samples, because of the find function

% Now, calculate the stdev on a sliding threshold from the positive MEP peak to determine
% CSP offset
A = 1;
CSP_End = [];

% We assume that the CSP lasts as long as Offset (25ms), and not longer than the current frame (defined by start_end)
for sample = Idx_Peak+Offset_Assess_CSP:length(diff_data)-Length_Sliding % -1 is because we work with differentiated data

    if std(diff_data(sample:sample+Length_Sliding)) > Threshold % Let's remember that threshold is based on differential data
        CSP_End(A) = sample;
        A = A+1;
    end

end


if ~isempty(CSP_End)
    CSP_Offset = CSP_End(1); % Only store the first index (there will be multiple indexes)
    Duration_in_Sec = (CSP_End(1)-Idx_Peak)/Rate; % In seconds
else
    CSP_Offset = NaN;
    Duration_in_Sec = NaN;
end

if ~isempty(CSP_End)
    if CSP_End(1) <= Idx_Peak+Offset_Assess_CSP % If the CSP offset happens at the same time as MEP peak+Offset (when we start looking, we NaN
        Duration_in_Sec = NaN;
    end
end