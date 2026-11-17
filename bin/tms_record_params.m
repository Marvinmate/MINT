function p=tms_record_params(p,rate,n)
  % Legacy sample settings are calibrated at 4000 Hz, never the acquisition rate.
  assert(isscalar(rate) && isfinite(rate) && rate>=1000,'Sampling rate must be >=1000 Hz; lower rates are not supported');
  assert(isscalar(n) && isfinite(n) && n==round(n) && n>1,'Invalid trial length');
  samples={'csp_offset_samples','baseline_offset_samples','baseline_duration_samples','sliding_samples','silence_samples','breakthrough_max_samples'};
  for field=samples
    value=p.(field{1}); assert(isscalar(value) && isfinite(value) && value>0,'Invalid historical duration');
    p.(field{1})=max(1,round(value*rate/4000));
  end
  % Search indices refer to samples of diff(), retaining the historical -1 convention.
  p.expect_mep_start=1+round((p.expect_mep_start-1)*rate/4000);
  p.expect_mep_end=1+round((p.expect_mep_end-1)*rate/4000);
  p.sgolay_frame=max(p.sgolay_order+2,1+2*round(p.sgolay_span_ms*rate/2000));
  assert(mod(p.sgolay_frame,2)==1 && p.sgolay_frame>p.sgolay_order && p.sgolay_frame<=n-1,'Invalid Savitzky-Golay frame for this trial');
  p.sgolay_effective_span_ms=(p.sgolay_frame-1)*1000/rate;
  if abs(p.sgolay_effective_span_ms-p.sgolay_span_ms)>1000/rate
    warning('MINT:SamplingResolution','SG span requested %.3g ms; effective %.3g ms (%d points at %g Hz)',p.sgolay_span_ms,p.sgolay_effective_span_ms,p.sgolay_frame,rate);
  end
  assert(round(p.mep_half_window_seconds*rate)>=1,'MEP measurement window is below sampling resolution');
  assert(round(p.mep_search_end_ms*rate/1000)>round(p.mep_search_start_ms*rate/1000),'MEP search is below sampling resolution');
  p.rate=rate; p.samples_per_trial=n; p.temporal_resolution_ms=1000/rate;
end
