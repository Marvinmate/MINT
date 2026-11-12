function [Breakthrough,Duration_in_Sec,Idx_Peak,CSP_Offset] = Calculate_CSP_v2(Max_Breakthrough_Duration,Trials,Time_Points,participant_list,EMG_Silence_Duration,part,data,Rate,start_end,window_MEP,Offset_Assess_CSP,Offset_Assess_Baseline,Bsln_Dur,Length_Sliding,Fraction_Of_Threshold)

Breakthrough = false; % By default, we flag trials as NOT containing breakthroughs

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
B = 1;
CSP_End = [];
Silent_EMG = [];

% We assume that the CSP lasts as long as Offset (25ms), and not longer than the current frame (defined by start_end)
for sample = Idx_Peak+Offset_Assess_CSP:length(diff_data)-Length_Sliding % -1 is because we work with differentiated data

    if std(diff_data(sample:sample+Length_Sliding)) > Threshold % Let's remember that threshold is based on differential data
        CSP_End(A) = sample;
        A = A+1;
    end

    if std(diff_data(sample:sample+Length_Sliding)) < Threshold % Let's remember that threshold is based on differential data
        Silent_EMG(B) = sample;
        B = B+1;
    end

end

% Make sure that here, we only report the periods of silent EMG AFTER the
% CSP Offset

Silent_EMG(Silent_EMG <= CSP_End(1)) = [];

% I need to validate whether this is the genuine CSP Offset.
% How can I do this? I can assess whether there is another silent period
% following the CSP end identified above. The problem is: "how far after"
% this CSP offset should I keep looking?

% Identify if there is still a period of silence after we determined our
% CSP offset
Idx_Silent = intersect(Silent_EMG,start_end);
Idx = [];
New_CSP_End = [];

A = 1;
for i = 1:length(Idx_Silent)-EMG_Silence_Duration
    
    if sum(diff(Idx_Silent(i:i+EMG_Silence_Duration))) == EMG_Silence_Duration % if the difference between 50 continuous samples is 50, it means they are continuous
        Idx(A) = i;
        A = A+1;
    end

end

% Recalculate the CSP Offset, if Idx is not empty
if ~isempty(Idx) && Idx_Silent(Idx(1))-CSP_End(1) <= Max_Breakthrough_Duration 
    warning('Possible EMG Breakthrough for ID%s, V%i, Trial %i, I adjusted the CSP Offset.',...
        char(participant_list(part)),Time_Points,Trials)
    disp(' ')

    Breakthrough = true;

    A = 1;

    % Calculate the CSP from the moment we identified as silent EMG above
    for sample = Idx_Silent(Idx(1)):length(diff_data)-Length_Sliding %

        if std(diff_data(sample:sample+Length_Sliding)) > Threshold % Let's remember that threshold is based on differential data
            New_CSP_End(A) = sample;
            A = A+1;
        end

    end

end

if ~isempty(New_CSP_End) % If we suspect there was breakthrough EMG, 
    % and we found a new CSP Offset, we use this new value
    CSP_End = New_CSP_End;
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