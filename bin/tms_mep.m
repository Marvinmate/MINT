function tms_mep(input,id,condition,time,protocol,key,settings)
  p=tms_init(settings); x=load(input);
  required={'data','datastart','dataend','samplerate','unittext','titles'};
  for k=1:numel(required), assert(isfield(x,required{k}),['Missing MAT field ' required{k}]); end
  channels=1; if strcmp(protocol,'IHI'), channels=4; end
  assert(size(x.datastart,1)==channels,'Unexpected channel count');
  assert(all(x.samplerate(:)==p.rate),'Unexpected samplerate');
  assert(all(x.dataend(:)-x.datastart(:)+1==p.samples_per_trial),'Unexpected trial length');
  assert(all(x.datastart(:)>=1) && all(x.dataend(:)<=numel(x.data)),'Invalid trial indices');
  assert(strcmp(strtrim(char(x.unittext)),'V'),'Historical inputs must be in V');
  assert(all(isfinite(x.data(:))),'Nonfinite raw data: explicit review required');
  d=struct('id',id,'condition',condition,'time',time,'protocol',protocol,'key',key,'rate',p.rate);
  d.raw=double(x.data); d.starts=x.datastart; d.ends=x.dataend; d.n=size(x.datastart,2);
  d.input_sha256=tms_sha256(input); d.amp=nan(d.n,2); d.onset=nan(d.n,2); d.offset=nan(d.n,2);
  d.windows=nan(d.n,2); d.stim=nan(d.n,2); d.flags=cell(d.n,2); d.classes=cell(d.n,1);
  if strcmp(protocol,'CSP')
    for tr=1:d.n
      se=x.datastart(tr):x.dataend(tr);
      [d.amp(tr,1),w]=Calculate_MEP(d.raw,se,p.mep_half_window_seconds,p.rate,p.expect_mep_start:p.expect_mep_end);
      d.windows(tr,:)=[w(1) w(end)]; d.onset(tr,1)=(w(1)+w(end))/2; d.offset(tr,1)=w(end); d.flags{tr,1}='Measured';
    end
  else
    assert(isequal(x.datastart(:),(1:p.samples_per_trial:numel(d.raw))'),'IHI layout does not match historical reshape');
    d.trials=reshape(d.raw(:),[p.samples_per_trial 4 d.n]);
    for tr=1:d.n
      a=d.trials(:,:,tr); sr=detect_TMS_pulse(a(:,3),p.rate); sl=detect_TMS_pulse(a(:,4),p.rate);
      d.stim(tr,:)=[sr sl]; d.classes{tr}=tms_ihi_condition(sr,sl,p.rate);
      left=a(:,2);
      if p.remove_60hz
        t=(0:p.samples_per_trial-1)'/p.rate; X=[sin(2*pi*60*t) cos(2*pi*60*t)]; left=left-X*(X\left);
      end
      % The supplied dataset always has a valid test pulse. Preserve a missing trial explicitly.
      assert(~isnan(sr),'Missing test pulse: the historical script cannot process this trial safely');
      [d.amp(tr,1),d.onset(tr,1),d.offset(tr,1),d.flags{tr,1}]=measure_MEP(a(:,1),sr+48,min(sr+240,1600),p.rate,p.mep_half_window_seconds);
      d.flags{tr,2}='Unconditioned';
      if any(strcmp(d.classes{tr},{'IHI_10ms','IHI_40ms'})) && ~isnan(sl)
        [d.amp(tr,2),d.onset(tr,2),d.offset(tr,2),d.flags{tr,2}]=measure_MEP(left,sl+48,min(sl+240,1600),p.rate,p.mep_half_window_seconds);
      end
    end
  end
  rows=cell(d.n,10);
  for tr=1:d.n
    rows(tr,:)={id,condition,['T' num2str(time)],protocol,tr,d.amp(tr,1)*1000,d.amp(tr,2)*1000,d.onset(tr,1),d.offset(tr,1),d.flags{tr,1}};
  end
  tms_write_tsv([key '.mep.tsv'],{'ID','Visit','Timepoint','Protocol','Trial','MEP_Right_mV','MEP_Left_mV','MEP_Centre_Index','MEP_Window_End','Status'},rows);
  save([key '.mep.mat'],'d','-v7');
  versions=struct('engine_version',version,'input_sha256',d.input_sha256,'parameters',p,'mode','historical','code',struct);
  sources=dir(fullfile(fileparts(mfilename('fullpath')),'*.m'));
  for i=1:numel(sources), versions.code.(strrep(sources(i).name,'.','_'))=tms_sha256(fullfile(sources(i).folder,sources(i).name)); end
  if exist('OCTAVE_VERSION','builtin')
    packages=pkg('list'); versions.packages=cellfun(@(x)struct('name',x.name,'version',x.version),packages,'UniformOutput',false);
  end
  tms_write_json([key '.provenance.json'],versions);
end
