function order=tms_conditions(records,p)
  observed=sort(unique(cellfun(@(d)d.condition,records,'UniformOutput',false)));
  historical={'Full','Half','Pbo'};
  if isfield(p,'condition_order') && ~isempty(p.condition_order)
    order=reshape(p.condition_order,1,[]);
    assert(iscellstr(order) && numel(unique(order))==numel(order),'condition_order must contain unique labels');
    assert(all(ismember(observed,order)),'condition_order must include every observed condition');
    order=order(ismember(order,observed));
  elseif all(ismember(observed,historical))
    order=historical(ismember(historical,observed));
  else
    order=reshape(observed,1,[]);
  end
end
