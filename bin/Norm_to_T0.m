function [All] = Norm_to_T0(All)

T0_v1_MEP = [];
T0_v1_CSP = [];

T0_v2_MEP = [];
T0_v2_CSP = [];

T0_v3_MEP = [];
T0_v3_CSP = [];

%% Calculate Baseline (T0) for each visit, for each participant
for part = 1:length(All) % Loop around Participants

    % Calculate mean of Baseline for each visit
    try
        T0_v1_MEP(part) = mean(All(part).MEP1(:,1),'omitnan'); % First column is T0
    catch
        T0_v1_MEP(part) = NaN;
    end

    try
        T0_v1_CSP(part) = mean(All(part).CSP_Duration1(:,1),'omitnan'); % First column is T0
    catch
        T0_v1_CSP(part) = NaN;
    end
    
    try
        T0_v2_MEP(part) = mean(All(part).MEP2(:,1),'omitnan');
    catch
        T0_v2_MEP(part) = NaN;
    end

    try
        T0_v2_CSP(part) = mean(All(part).CSP_Duration2(:,1),'omitnan');
    catch
        T0_v2_CSP(part) = NaN;
    end

    try
        T0_v3_MEP(part) = mean(All(part).MEP3(:,1),'omitnan');
    catch
        T0_v3_MEP(part) = NaN;
    end

    try
        T0_v3_CSP(part) = mean(All(part).CSP_Duration3(:,1),'omitnan');
    catch
        T0_v3_CSP(part) = NaN;
    end

end % End of loop on participants

%% Normalise Data to Baseline
for part = 1:length(All)

    try % Session 1 - MEP
        num_trial = length(All(part).MEP1(:,1));
        All(part).MEP1_Norm(:,1) = ones(num_trial,1); % Fill with ones for T0 (since it becomes the baseline)
        All(part).MEP1_Norm(:,2:6) = All(part).MEP1(:,2:6)./T0_v1_MEP(part);
    catch
        All(part).MEP1_Norm = []; % If we can't baseline normalise, empty cell
    end

    try % Session 1 - CSP
        num_trial = length(All(part).CSP_Duration1(:,1));
        All(part).CSP1_Norm(:,1) = ones(num_trial,1); % Fill with ones for T0 (since it becomes the baseline)
        All(part).CSP1_Norm(:,2:6) = All(part).CSP_Duration1(:,2:6)./T0_v1_CSP(part);
    catch
        All(part).CSP1_Norm = []; % If we can't baseline normalise, empty cell
    end

    try % Session 2 - MEP
        num_trial = length(All(part).MEP2(:,1));
        All(part).MEP2_Norm(:,1) = ones(num_trial,1); % Fill with ones for T0 (since it becomes the baseline)
        All(part).MEP2_Norm(:,2:6) = All(part).MEP2(:,2:6)./T0_v2_MEP(part);
    catch
        All(part).MEP2_Norm = []; % If we can't baseline normalise, empty cell
    end

    try % Session 2 - CSP
        num_trial = length(All(part).CSP_Duration2(:,1));
        All(part).CSP2_Norm(:,1) = ones(num_trial,1); % Fill with ones for T0 (since it becomes the baseline)
        All(part).CSP2_Norm(:,2:6) = All(part).CSP_Duration2(:,2:6)./T0_v2_CSP(part);
    catch
        All(part).CSP2_Norm = []; % If we can't baseline normalise, empty cell
    end

    try % Session 3 - MEP
        num_trial = length(All(part).MEP3(:,1));
        All(part).MEP3_Norm(:,1) = ones(num_trial,1); % Fill with ones for T0 (since it becomes the baseline)
        All(part).MEP3_Norm(:,2:6) = All(part).MEP3(:,2:6)./T0_v3_MEP(part);
    catch
        All(part).MEP3_Norm = []; % If we can't baseline normalise, empty cell
    end

    try % Session 3 - CSP
        num_trial = length(All(part).CSP_Duration3(:,1));
        All(part).CSP3_Norm(:,1) = ones(num_trial,1); % Fill with ones for T0 (since it becomes the baseline)
        All(part).CSP3_Norm(:,2:6) = All(part).CSP_Duration3(:,2:6)./T0_v3_CSP(part);
    catch
        All(part).CSP3_Norm = []; % If we can't baseline normalise, empty cell
    end

end % End of loop on participants


end % End of function