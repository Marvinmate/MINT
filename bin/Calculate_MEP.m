function [temp_MEPAmp,window_MEP] = Calculate_MEP(data,start_end,Sec,Rate,Expect_MEP)

idx_MEP = NaN; % Reinitialise variable
diff_data = [];
window_MEP = [];
temp_MEPamp = NaN;

diff_data = diff(data(start_end)); % Find MEPs based on the differential; this allows us to ignore all of the slowdrifts in the signal, and only focus on the abrupt changes in the signal

diff_data = sgolayfilt(diff_data,3,11); % Smooth out the imperfection so we don't capture a spurious spike as the peak

% Find the center of the MEP
temp = find(max(diff_data(Expect_MEP)) == diff_data); % Biggest change signals the centre of the MEP

% Only take the first index from temp, and add the data start -1 to realign
% the index with the full trial
idx_MEP = temp(1) + start_end(1)-1; % Must add datastart to realign the index with the whole trial
        
window_MEP = idx_MEP-Sec*Rate:idx_MEP+Sec*Rate;

temp_MEPAmp = max(data(window_MEP))-...
                min(data(window_MEP)); % Calculate amplitude in the window we predefined

end