function y=tms_render_limits(values)
  values=values(isfinite(values));
  if isempty(values), y=[-1 1]; return; end
  lo=min(values(:)); hi=max(values(:)); span=max(hi-lo,1e-6);
  y=[lo-.08*span hi+.12*span];
end
