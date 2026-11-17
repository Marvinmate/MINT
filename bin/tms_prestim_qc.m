function q=tms_prestim_qc(signals,reference,rate,p)
  % Raw volts, peak-to-peak per channel. Window precedes the earliest TTL ONSET.
  % This QC reference does not change the peak-based scientific timing.
  q=struct('value_uv',NaN,'right_uv',NaN,'left_uv',NaN,'exceeded',NaN,...
    'status','Disabled','start_index',NaN,'end_index',NaN,'included',true,'reference_index',reference);
  if ~p.prestim_qc_enabled, return; end
  if ~isfinite(reference), q.status='MissingReference'; return; end
  a=reference+round(p.prestim_start_ms*rate/1000); b=reference+round(p.prestim_end_ms*rate/1000);
  q.start_index=a; q.end_index=b;
  if a<1 || b>size(signals,1) || b>=reference || a>=b
    q.status='UnavailableWindow'; return;
  end
  values=(max(signals(a:b,:),[],1)-min(signals(a:b,:),[],1))*1e6;
  if any(~isfinite(values)), q.status='MissingSignal'; return; end
  q.right_uv=values(1); if numel(values)>1, q.left_uv=values(2); end
  q.value_uv=max(values); q.exceeded=q.value_uv>p.prestim_threshold_uv;
  q.status='Pass'; if q.exceeded, q.status='AboveThreshold'; end
  q.included=~(p.prestim_qc_exclude && q.exceeded);
end
