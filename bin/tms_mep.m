function tms_mep(input,id,condition,time,protocol,key,settings)
  p=tms_init(settings); x=load(input);
  required={'data','datastart','dataend','samplerate','unittext','titles'};
  for k=1:numel(required), assert(isfield(x,required{k}),['Missing MAT field ' required{k}]); end
  channels=1; if strcmp(protocol,'IHI'), channels=4; end
  assert(size(x.datastart,1)==channels,'Unexpected channel count');
  rate=double(x.samplerate(1)); lengths=x.dataend-x.datastart+1;
  assert(all(isfinite(x.samplerate(:))) && all(x.samplerate(:)==rate),'Mixed or missing samplerates within a recording');
  assert(isequal(size(x.datastart),size(x.dataend)) && all(lengths(:)==lengths(1)),'Unequal trial/channel lengths');
  assert(all(x.datastart(:)==round(x.datastart(:))) && all(x.dataend(:)==round(x.dataend(:))),'Noninteger trial indices');
  p=tms_record_params(p,rate,double(lengths(1)));
  assert(all(x.datastart(:)>=1) && all(x.dataend(:)<=numel(x.data)),'Invalid trial indices');
  assert(strcmp(strtrim(char(x.unittext)),'V'),'Historical inputs must be in V');
  assert(all(isfinite(x.data(:))),'Nonfinite raw data: explicit review required');
  % MAT exporters may encode index arrays as integers; arithmetic must stay floating-point.
  x.datastart=double(x.datastart); x.dataend=double(x.dataend);
  d=struct('id',id,'condition',condition,'time',time,'protocol',protocol,'key',key,'rate',p.rate);
  d.raw=double(x.data); d.starts=x.datastart; d.ends=x.dataend; d.n=size(x.datastart,2);
  d.input_sha256=tms_sha256(input); d.amp=nan(d.n,2); d.onset=nan(d.n,2); d.offset=nan(d.n,2);
  d.windows=nan(d.n,2); d.stim=nan(d.n,2); d.flags=cell(d.n,2); d.classes=cell(d.n,1);
  d.parameters=p; d.ttl=nan(d.n,2,4); d.measurement_starts=nan(d.n,2); d.search_windows=nan(d.n,2,2);
  d.qc=repmat(tms_prestim_qc(zeros(2,1),NaN,p.rate,p),d.n,1); d.included=true(d.n,1);
  if strcmp(protocol,'CSP')
    assert(p.expect_mep_start>=1 && p.expect_mep_end<p.samples_per_trial && p.expect_mep_end+round(p.mep_half_window_seconds*p.rate)<=p.samples_per_trial,'CSP MEP search/measurement outside trial');
    for tr=1:d.n
      se=x.datastart(tr):x.dataend(tr);
      [d.amp(tr,1),w]=Calculate_MEP(d.raw,se,p.mep_half_window_seconds,p.rate,p.expect_mep_start:p.expect_mep_end,p.sgolay_frame);
      d.windows(tr,:)=[w(1) w(end)]; d.onset(tr,1)=(w(1)+w(end))/2; d.offset(tr,1)=w(end); d.flags{tr,1}='Measured';
      d.measurement_starts(tr,1)=w(1);
      reference=NaN; if ~isempty(p.csp_stimulus_time_ms), reference=1+round(p.csp_stimulus_time_ms*p.rate/1000); end
      d.qc(tr)=tms_prestim_qc(reshape(d.raw(se),[],1),reference,p.rate,p);
      d.included(tr)=d.qc(tr).included;
    end
  else
    assert(isequal(x.datastart(:),(1:p.samples_per_trial:numel(d.raw))'),'IHI layout does not match historical reshape');
    d.trials=reshape(d.raw(:),[p.samples_per_trial 4 d.n]);
    for tr=1:d.n
      a=d.trials(:,:,tr); [sr,er]=detect_TMS_pulse(a(:,3),p.rate); [sl,el]=detect_TMS_pulse(a(:,4),p.rate);
      d.ttl(tr,1,:)=[er.start er.peak er.end er.duration_ms]; d.ttl(tr,2,:)=[el.start el.peak el.end el.duration_ms];
      onsets=[er.start el.start]; onsets=onsets(isfinite(onsets)); reference=NaN; if ~isempty(onsets), reference=min(onsets); end
      d.qc(tr)=tms_prestim_qc(a(:,1:2),reference,p.rate,p); d.included(tr)=d.qc(tr).included;
      d.stim(tr,:)=[sr sl]; d.classes{tr}=tms_ihi_condition(sr,sl,p.rate);
      left=a(:,2);
      if p.remove_60hz
        t=(0:p.samples_per_trial-1)'/p.rate; X=[sin(2*pi*60*t) cos(2*pi*60*t)]; left=left-X*(X\left);
      end
      % The supplied dataset always has a valid test pulse. Preserve a missing trial explicitly.
      assert(~isnan(sr),'Missing test pulse: the historical script cannot process this trial safely');
      [d.amp(tr,1),d.onset(tr,1),d.offset(tr,1),d.flags{tr,1}]=measure_MEP(a(:,1),sr+round(p.mep_search_start_ms*p.rate/1000),min(sr+round(p.mep_search_end_ms*p.rate/1000),p.samples_per_trial),p.rate,p.mep_half_window_seconds);
      d.search_windows(tr,1,:)=[max(2,sr+round(p.mep_search_start_ms*p.rate/1000)) min(sr+round(p.mep_search_end_ms*p.rate/1000),p.samples_per_trial)];
      d.flags{tr,2}='Unconditioned';
      if any(strcmp(d.classes{tr},{'IHI_10ms','IHI_40ms'})) && ~isnan(sl)
        [d.amp(tr,2),d.onset(tr,2),d.offset(tr,2),d.flags{tr,2}]=measure_MEP(left,sl+round(p.mep_search_start_ms*p.rate/1000),min(sl+round(p.mep_search_end_ms*p.rate/1000),p.samples_per_trial),p.rate,p.mep_half_window_seconds);
        d.search_windows(tr,2,:)=[max(2,sl+round(p.mep_search_start_ms*p.rate/1000)) min(sl+round(p.mep_search_end_ms*p.rate/1000),p.samples_per_trial)];
      end
      for ch=1:2
        if isfinite(d.onset(tr,ch)), d.measurement_starts(tr,ch)=max(1,d.onset(tr,ch)-round(p.mep_half_window_seconds*p.rate)); end
      end
    end
  end
  rows=cell(d.n,21);
  for tr=1:d.n
    rows(tr,:)={id,condition,['T' num2str(time)],protocol,tr,d.amp(tr,1)*1000,d.amp(tr,2)*1000,d.onset(tr,1),d.offset(tr,1),d.flags{tr,1},d.qc(tr).value_uv,d.qc(tr).right_uv,d.qc(tr).left_uv,d.qc(tr).exceeded,d.qc(tr).status,d.qc(tr).start_index,d.qc(tr).end_index,d.included(tr),d.rate,d.qc(tr).reference_index,'peak-to-peak raw; max over channels'};
  end
  tms_write_tsv([key '.mep.tsv'],{'ID','Visit','Timepoint','Protocol','Trial','MEP_Right_mV','MEP_Left_mV','MEP_Centre_Index','MEP_Window_End','Status','Prestim_PTP_uV','Prestim_Right_uV','Prestim_Left_uV','Prestim_Exceeded','Prestim_Status','Prestim_Start_Index','Prestim_End_Index','Included','Sampling_Rate_Hz','Prestim_Reference_Index','Prestim_Metric'},rows);
  save([key '.mep.mat'],'d','-v7');
  versions=struct('engine_version',version,'input_sha256',d.input_sha256,'parameters',p,'mode','v2-configurable; TTL peak reference','code',struct);
  sources=dir(fullfile(fileparts(mfilename('fullpath')),'*.m'));
  for i=1:numel(sources), versions.code.(strrep(sources(i).name,'.','_'))=tms_sha256(fullfile(sources(i).folder,sources(i).name)); end
  if exist('OCTAVE_VERSION','builtin')
    packages=pkg('list'); versions.packages=cellfun(@(x)struct('name',x.name,'version',x.version),packages,'UniformOutput',false);
  end
  tms_write_json([key '.provenance.json'],versions);
end
