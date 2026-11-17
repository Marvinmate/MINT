function All=Norm_to_T0(All)
  % Historical convention: each T0 row is 1; later trials / finite T0 mean.
  % Discover numeric condition slots instead of assuming exactly three visits.
  for part=1:numel(All)
    fields=fieldnames(All(part));
    for k=1:numel(fields)
      token=regexp(fields{k},'^MEP([0-9]+)$','tokens','once');
      if isempty(token), continue; end
      v=token{1};
      for pair={{['MEP' v],['MEP' v '_Norm']},{['CSP_Duration' v],['CSP' v '_Norm']}}
        names=pair{1}; M=All(part).(names{1});
        if isempty(M), All(part).(names{2})=[]; continue; end
        baseline=mean(M(:,1),'omitnan');
        N=nan(size(M)); N(:,1)=ones(size(M,1),1); N(:,2:end)=M(:,2:end)./baseline;
        All(part).(names{2})=N;
      end
    end
  end
end
