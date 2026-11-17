function p=tms_init(settings)
  if exist('OCTAVE_VERSION','builtin'), pkg('load','signal'); end
  p=jsondecode(fileread(settings));
  defaults=struct('mep_search_start_ms',12,'mep_search_end_ms',60,...
    'prestim_qc_enabled',false,'prestim_qc_exclude',false,'prestim_start_ms',-50,...
    'prestim_end_ms',-5,'prestim_threshold_uv',50,'csp_end_method','breakthrough-aware',...
    'csp_stimulus_time_ms',[],'condition_order',{{}},'sgolay_span_ms',2.5,'sgolay_order',3);
  for field=fieldnames(defaults)'
    if ~isfield(p,field{1}), p.(field{1})=defaults.(field{1}); end
  end
  finite_scalar(p.mep_search_start_ms,'mep_search_start_ms'); finite_scalar(p.mep_search_end_ms,'mep_search_end_ms');
  assert(p.mep_search_start_ms>=0 && p.mep_search_end_ms>p.mep_search_start_ms,'MEP search requires 0 <= start < end (ms)');
  finite_scalar(p.prestim_start_ms,'prestim_start_ms'); finite_scalar(p.prestim_end_ms,'prestim_end_ms');
  assert(p.prestim_start_ms<p.prestim_end_ms && p.prestim_end_ms<0,'QC requires start < end < 0 ms');
  finite_scalar(p.prestim_threshold_uv,'prestim_threshold_uv'); assert(p.prestim_threshold_uv>0,'QC threshold must be positive');
  for name={'prestim_qc_enabled','prestim_qc_exclude','remove_60hz'}
    value=p.(name{1}); assert(isscalar(value) && (islogical(value) || (isnumeric(value) && ismember(value,[0 1]))),[name{1} ' must be boolean']);
  end
  assert(~p.prestim_qc_exclude || p.prestim_qc_enabled,'QC exclusion requires QC enabled');
  assert(any(strcmp(p.csp_end_method,{'standard','breakthrough-aware'})),'csp_end_method must be standard or breakthrough-aware');
  assert(isempty(p.csp_stimulus_time_ms) || (isnumeric(p.csp_stimulus_time_ms) && isscalar(p.csp_stimulus_time_ms) && isfinite(p.csp_stimulus_time_ms) && p.csp_stimulus_time_ms>=0),'Invalid CSP stimulation time');
  assert(p.sgolay_order==3 && isscalar(p.sgolay_order),'Historical SG order must remain 3');
  finite_scalar(p.sgolay_span_ms,'sgolay_span_ms'); assert(p.sgolay_span_ms>0,'SG span must be positive');
  finite_scalar(p.mep_half_window_seconds,'mep_half_window_seconds'); assert(p.mep_half_window_seconds>0,'MEP half-window must be positive');
end
function finite_scalar(v,name)
  assert(isnumeric(v) && isscalar(v) && isfinite(v),[name ' must be a finite numeric scalar']);
end
