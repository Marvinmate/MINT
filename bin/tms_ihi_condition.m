function condition=tms_ihi_condition(right,left,rate)
  if isnan(left), condition='Unconditioned_MEP';
  elseif isnan(right), condition='Unknown';
  else
    delta=abs(right-left)/rate*1000;
    if abs(delta-10)<=5, condition='IHI_10ms';
    elseif abs(delta-40)<=5, condition='IHI_40ms';
    else, condition='Unknown'; end
  end
end
