function tms_multiqc_content(files, analyses, missing_file, out, science_file, run_json, versions_file)
  % Report only. Scientific values originate in the declared TSV inputs.
  if ~exist(out,'dir'), mkdir(out); end
  enabled=strsplit(analyses,',');
  p=jsondecode(fileread(science_file));
  run=jsondecode(run_json);
  records=struct; sources=cell(1,numel(files)); aggregates={};
  for i=1:numel(files)
    [~,stem,ext]=fileparts(files{i}); name=[stem ext];
    [t,h]=read_tsv(files{i});
    sources{i}=struct('file',name,'sha256',hash('sha256',fileread(files{i})),'rows',size(t,1));
    match=regexp(stem,'\.(mep|csp|ihi)$','tokens','once');
    if isempty(match)
      aggregates(end+1,:)={name,t,h};
      continue;
    end
    if isempty(t), continue; end
    axis=upper(match{1});
    protocol=axis;
    if strcmp(axis,'MEP'), protocol=t{1,h.Protocol}; end
    key=recording_key(protocol,t{1,h.ID},t{1,h.Visit},t{1,h.Timepoint});
    if ~isfield(records,key), records.(key)=struct; end
    assert(~isfield(records.(key),axis),['Duplicate report source: ' name]);
    assert(all(strcmp(t(:,h.ID),t{1,h.ID}) & strcmp(t(:,h.Visit),t{1,h.Visit}) & ...
      strcmp(t(:,h.Timepoint),t{1,h.Timepoint})),['Mixed recording metadata: ' name]);
    records.(key).(axis)=struct('name',name,'values',{t},'header',h);
  end

  [missing,~]=read_tsv(missing_file);
  missing_keys=cell(size(missing,1),1);
  qc=struct; ledger={}; samples={}; participants={}; trials=0;
  counts=zeros(1,4); breakthroughs=0; csp_eligible=0;
  for key=fieldnames(records)'
    key=key{1}; rec=records.(key);
    assert(isfield(rec,'MEP'),['Missing MEP export: ' key]);
    mep=rec.MEP; t=mep.values; h=mep.header; n=size(t,1);
    id=t{1,h.ID}; visit=t{1,h.Visit}; time=t{1,h.Timepoint}; protocol=t{1,h.Protocol};
    participants{end+1}=id; trials=trials+n;
    trial_ids=number(mep,'Trial');
    assert(numel(unique(trial_ids))==n,['Duplicate trials: ' mep.name]);
    right=number(mep,'MEP_Right_mV'); left=number(mep,'MEP_Left_mV');
    status=t(:,h.Status);
    q=qc_row('Present',n);
    q.Right_available=sum(isfinite(right)); q.Right_missing=n-q.Right_available;
    if strcmp(protocol,'IHI')
      q.Right_no_detection=sum(strcmp(status,'No MEP Detected'));
      q.Right_below_50=sum(isfinite(right) & right<0.05);
    end
    samples=[samples; sample_rows('MEP',protocol,id,visit,time,'',right)];
    if strcmp(protocol,'IHI')
      samples=[samples; sample_rows('MEP left',protocol,id,visit,time,'',left)];
    end
    ledger=[ledger; ledger_rows(mep,'MEP',protocol,key,trial_ids,'',zeros(n,1))];

    if isfield(rec,'CSP')
      csp=rec.CSP; ids=number(csp,'Trial');
      assert(isequal(sort(trial_ids),sort(ids)),['CSP/MEP trial mismatch: ' key]);
      durations=number(csp,'CSP_v2_ms'); flags=number(csp,'Breakthrough');
      q.CSP_available=sum(isfinite(durations)); q.CSP_missing=n-q.CSP_available;
      q.Breakthroughs=sum(flags==1); q.Breakthrough_evaluable=sum(flags==0 | flags==1);
      q.Breakthrough_unknown=n-q.Breakthrough_evaluable;
      breakthroughs=breakthroughs+q.Breakthroughs; csp_eligible=csp_eligible+q.Breakthrough_evaluable;
      samples=[samples; sample_rows('CSP v2','CSP',id,visit,time,'',durations)];
      ledger=[ledger; ledger_rows(csp,'CSP','CSP',key,ids,'',zeros(n,1))];
    end

    if isfield(rec,'IHI')
      ihi=rec.IHI; ids=number(ihi,'Trial');
      assert(isequal(sort(trial_ids),sort(ids)),['IHI/MEP trial mismatch: ' key]);
      classes=ihi.values(:,ihi.header.Condition);
      class_names={'IHI_10ms','IHI_40ms','Unconditioned_MEP','Unknown'};
      class_counts=cellfun(@(c)sum(strcmp(classes,c)),class_names);
      assert(sum(class_counts)==n,['Unexpected IHI classification: ' key]);
      counts=counts+class_counts;
      q.IHI10=class_counts(1); q.IHI40=class_counts(2);
      q.Unconditioned=class_counts(3); q.Unknown=class_counts(4);
      q.All_unconditioned=double(q.Unconditioned==n);
      q.Test_missing=sum(~isfinite(number(ihi,'Test_Pulse_Index')));
      q.Conditioning_missing=sum(~isfinite(number(ihi,'Conditioning_Pulse_Index')));
      conditioned=ismember(classes,class_names(1:2)); ihi_left=number(ihi,'MEP_Left_mV');
      q.Left_eligible=sum(conditioned);
      q.Left_available=sum(conditioned & isfinite(ihi_left));
      q.Left_missing=q.Left_eligible-q.Left_available;
      q.Left_not_applicable=sum(~conditioned);
      q.Left_below_50=sum(conditioned & isfinite(ihi_left) & ihi_left<0.05);
      samples=[samples; sample_rows('IHI test','IHI',id,visit,time,classes,number(ihi,'MEP_Right_mV'))];
      ledger=[ledger; ledger_rows(ihi,'IHI','IHI',key,ids,classes,zeros(n,1))];
    end

    flags={'Right_missing','Right_no_detection','Right_below_50','CSP_missing','Breakthroughs', ...
           'Breakthrough_unknown','Unknown','Test_missing','All_unconditioned','Left_missing','Left_below_50'};
    labels={'Test MEP missing','No right MEP detected','Right <50 µV','CSP v2 missing','CSP breakthrough', ...
            'Breakthrough flag unavailable','Unknown class','Test pulse absent','All Unconditioned','Left MEP missing','Left <50 µV'};
    active=cellfun(@(f)q.(f)>0,flags);
    q.Review=double(any(active));
    q.Reasons=strjoin(labels(active),'; ');
    qc.(key)=q;
  end

  for i=1:size(missing,1)
    fields=strsplit(missing{i,1},'/');
    assert(numel(fields)==4,['Invalid missing-recording entry: ' missing{i,1}]);
    key=recording_key(fields{:}); missing_keys{i}=key;
    assert(~isfield(qc,key),['Recording marked both present and missing: ' key]);
    qc.(key)=qc_row('Absent',0);
    qc.(key).Review=1; qc.(key).Reasons='Absent acquisition';
  end
  ledger=[ledger; aggregate_ledger(aggregates,records)];
  write_tsv(fullfile(out,'report_values.tsv'), ...
    {'Module','Protocol','Participant','Condition','Timepoint','Trial','Class','MEP_Right_mV','MEP_Left_mV','CSP_ms', ...
     'MEP_Norm_pct','CSP_Norm_pct','Breakthrough','Status','Test_Pulse_Index','Conditioning_Pulse_Index','Padding','SourceFile','SourceRow','Recording'},ledger);

  keys=fieldnames(qc);
  review=cellfun(@(key)qc.(key).Review,keys);
  [~,order]=sort(review,'descend');
  qc=orderfields(qc,order);
  write_qc(out,qc);
  present_review=sum(review)-numel(missing_keys);
  summary=sprintf(['<p><strong>%d</strong> participants &nbsp; · &nbsp; <strong>%d</strong> recordings &nbsp; · &nbsp; ' ...
    '<strong>%d</strong> processed trials</p><p>Modules: <strong>%s</strong> &nbsp; · &nbsp; ' ...
    '%d processed recordings to review &nbsp; · &nbsp; %d absent acquisitions.</p>'], ...
    numel(unique(participants)),numel(fieldnames(records)),trials,strjoin(upper(enabled),', '),present_review,numel(missing_keys));
  content(out,'overview','run','Run summary','html', ...
    'Each trial is counted once from the MEP export, across both acquisition protocols.',struct,summary);

  help=['Review flags an observed missing measurement, IHI detection status or amplitude below 50 µV, Unknown class, ' ...
    'all-Unconditioned IHI recording, CSP breakthrough or unavailable breakthrough flag, or an absent acquisition. ' ...
    'A flag calls for review and carries no exclusion rule. An absent conditioning pulse often explains an Unconditioned label. ' ...
    'Left IHI measurement applies to IHI10 and IHI40. Dashes or blank cells indicate that a metric is unavailable or inapplicable. ' ...
    'The 50 µV count uses finite amplitudes strictly below 0.05 mV. Right detection status is reported separately. ' ...
    'MAT import errors and a missing required test pulse can stop the run before the report is generated. Check the Nextflow log in that case.'];
  fields=fieldnames(qc.(keys{1}));
  titles={'Review','Import','Trials','Test MEP n','Test MEP missing','Right: no MEP detected','Right <50 µV', ...
    'Test pulse absent','Conditioning pulse absent','Unknown class','All Unconditioned','Left eligible','Left measured', ...
    'Left missing','Left not applicable','Left <50 µV','CSP v2 n','CSP v2 missing','Breakthroughs','Breakthrough evaluable', ...
    'Breakthrough unavailable','IHI10','IHI40','Unconditioned','Review reasons'};
  headers=struct;
  for i=1:numel(fields)
    visible=ismember(fields{i},{'Review','Import','Trials','Right_available','Right_missing','Unknown','Reasons'});
    headers.(fields{i})=struct('title',titles{i},'placement',i,'scale',false,'hidden',~visible);
  end
  content(out,'overview','qc','Table · recording QC','table', ...
    'Filter in the MultiQC Toolbox by the recording label (protocol, participant, condition and time). Use Configure Columns for secondary metrics and Download for table data.', ...
    struct('col1_header','Protocol | Participant | Condition | Time','sort_rows',false,'no_violin',true),qc,struct('headers',headers,'helptext',help));

  mep_metrics={'MEP','CSP','CSP · single EMG';'MEP','IHI','IHI · right test EMG';'MEP left','IHI','IHI · left EMG'};
  if p.remove_60hz, mep_metrics{3,3}='IHI · left EMG (60 Hz corrected)'; end
  trend_rows=metric_plots(out,'mep',mep_metrics,samples,'MEP amplitude (mV)');
  if ismember('csp',enabled)
    trend_rows=[trend_rows; metric_plots(out,'csp',{'CSP v2','CSP','CSP v2'},samples,'CSP v2 duration (ms)')];
    [data,categories]=qc_bar(qc,'Breakthroughs','CSP');
    if ~isempty(fieldnames(data))
      content(out,'csp','breakthrough','3 · Breakthroughs','bargraph', ...
        sprintf('%d of %d evaluable trials had a breakthrough. Counts use the exported 0/1 flag; the percentage denominator is the sum of both bars for each recording. See QC for unavailable flags.',breakthroughs,csp_eligible), ...
        struct('ylab','Trials','cpswitch',true,'hide_zero_cats',false),data,struct('categories',categories));
    end
  end
  if ismember('ihi',enabled)
    [data,categories]=qc_bar(qc,'IHI10','IHI');
    if ~isempty(fieldnames(data))
      content(out,'ihi','classes','1 · Detected classes','bargraph', ...
        'Counts use all IHI trial rows. The percentage view divides by all four classes for each recording. A recording with only Unconditioned is marked in recording QC.', ...
        struct('ylab','Trials','cpswitch',true,'hide_zero_cats',false),data,struct('categories',categories));
    end
    class_boxes(out,samples);
    content(out,'ihi','qc','3 · Stimulation and measurement QC','html', ...
      'See recording QC for the available test and conditioning pulse indices, Unknown classes, and right and applicable left amplitudes.',struct, ...
      '<p><a href="#tms_overview_qc">Open recording QC</a>. Configure Columns exposes left eligibility, below-threshold counts and class totals.</p>');
  end
  write_tsv(fullfile(out,'report_trends.tsv'),{'Metric','Protocol','Participant','Condition','Timepoint','N','Mean'},trend_rows);
  methods(out,p,run,enabled,versions_file,science_file);
  evidence=struct('analyses',{enabled},'sources',{sources},'participants',{unique(participants)}, ...
    'recordings',numel(fieldnames(records)),'trials',trials,'processed_review',present_review, ...
    'missing_recordings',{missing_keys},'breakthroughs',breakthroughs,'breakthrough_evaluable',csp_eligible, ...
    'ihi10',counts(1),'ihi40',counts(2),'unconditioned',counts(3),'unknown',counts(4));
  write_json(fullfile(out,'report_evidence.json'),evidence);
end

function q=qc_row(import,n)
  q=struct('Review',0,'Import',import,'Trials',n,'Right_available',NaN,'Right_missing',NaN,'Right_no_detection',NaN, ...
    'Right_below_50',NaN,'Test_missing',NaN,'Conditioning_missing',NaN,'Unknown',NaN,'All_unconditioned',NaN, ...
    'Left_eligible',NaN,'Left_available',NaN,'Left_missing',NaN,'Left_not_applicable',NaN,'Left_below_50',NaN, ...
    'CSP_available',NaN,'CSP_missing',NaN,'Breakthroughs',NaN,'Breakthrough_evaluable',NaN,'Breakthrough_unknown',NaN, ...
    'IHI10',NaN,'IHI40',NaN,'Unconditioned',NaN,'Reasons','');
end

function rows=sample_rows(metric,protocol,id,visit,time,classes,values)
  n=numel(values);
  if ischar(classes), classes=repmat({classes},n,1); end
  rows=[repmat({metric,protocol,id,visit,time},n,1) classes num2cell(values)];
end

function rows=metric_plots(out,section,metrics,samples,unit)
  trend={}; boxes={}; labels_trend={}; labels_box={}; rows=cell(0,7);
  for i=1:size(metrics,1)
    metric=metrics{i,1}; protocol=metrics{i,2}; name=metrics{i,3};
    set=samples(strcmp(samples(:,1),metric) & strcmp(samples(:,2),protocol),:);
    if isempty(set), continue; end
    values=cell2mat(set(:,7));
    by_series=struct; by_box=struct; colors=struct; dashes=struct;
    groups=unique(cellfun(@(id,visit)[id ' | ' visit],set(:,3),set(:,4),'UniformOutput',false));
    for j=1:numel(groups)
      group=strsplit(groups{j},' | '); id=group{1}; visit=group{2};
      pick=strcmp(set(:,3),id) & strcmp(set(:,4),visit) & isfinite(values);
      if ~any(pick), continue; end
      key=['ID ' id ' | ' visit]; points=struct;
      for t=0:5
        time=sprintf('T%d',t); v=values(pick & strcmp(set(:,5),time));
        avg=NaN;
        if ~isempty(v), avg=mean(v); end
        points.(time)=avg;
        rows(end+1,:)={metric,protocol,id,visit,time,numel(v),avg};
      end
      by_series.(key)=points;
      switch visit
        case 'Full', colors.(key)='#0072B2'; dashes.(key)='solid';
        case 'Half', colors.(key)='#D55E00'; dashes.(key)='dash';
        case 'Pbo', colors.(key)='#009E73'; dashes.(key)='dot';
      end
    end
    for visit=unique(set(:,4))'
      for t=0:5
        time=sprintf('T%d',t);
        v=values(strcmp(set(:,4),visit{1}) & strcmp(set(:,5),time) & isfinite(values));
        if ~isempty(v), by_box.(sprintf('%s | %s (n=%d)',visit{1},time,numel(v)))=num2cell(v); end
      end
    end
    if ~isempty(fieldnames(by_series))
      trend{end+1}=by_series;
      labels_trend{end+1}=struct('name',name,'colors',colors,'dash_styles',dashes);
    end
    if ~isempty(fieldnames(by_box)), boxes{end+1}=by_box; labels_box{end+1}=name; end
  end
  if ~isempty(trend)
    config=struct('xlab','Acquisition','ylab',unit,'categories',true,'style','lines+markers','showlegend',true,'smooth_points',NaN);
    config.data_labels=labels_trend;
    if numel(labels_trend)==1
      config.colors=labels_trend{1}.colors;
      config.dash_styles=labels_trend{1}.dash_styles;
    end
    tabs='';
    if numel(trend)>1, tabs='Use the channel tabs to switch datasets. '; end
    content(out,section,'trend','1 · Acquisition trends','linegraph', ...
      ['Arithmetic mean of finite exported trials for each participant, condition and acquisition. A missing mean breaks the line. ' ...
       tabs 'Toggle series in the legend or filter with the Toolbox. T0–T5 are acquisition labels. ' ...
       'Counts and means for each point are exported in report_trends.tsv.'],config,trend);
  end
  if isempty(trend)
    content(out,section,'availability','1 · Availability','html', ...
      'The selected module supplied no finite values for the acquisition summaries.',struct,'<p>See recording QC for availability.</p>');
  end
  if ~isempty(boxes)
    config=struct('ylab',unit,'sort_samples',false); config.data_labels=labels_box;
    content(out,section,'distribution','2 · Trial distributions','box', ...
      ['Individual finite trial values pooled across participants within each condition and acquisition. ' ...
       'Each label shows the number of trials. Boxes show the median and interquartile range; point values are downloadable.'],config,boxes);
  end
end

function [data,categories]=qc_bar(qc,field,protocol)
  data=struct;
  for key=fieldnames(qc)'
    k=key{1}; q=qc.(k);
    if ~startsWith(k,[protocol ' |']) || ~isfinite(q.(field)), continue; end
    if strcmp(protocol,'CSP')
      if q.Breakthrough_evaluable==0, continue; end
      data.(k)=struct('Yes',q.Breakthroughs,'No',q.Breakthrough_evaluable-q.Breakthroughs);
    else
      data.(k)=struct('IHI10',q.IHI10,'IHI40',q.IHI40,'Unconditioned',q.Unconditioned,'Unknown',q.Unknown);
    end
  end
  if strcmp(protocol,'CSP')
    categories=struct('Yes',struct('name','Breakthrough','color','#D55E00'), ...
                      'No',struct('name','No breakthrough','color','#0072B2'));
  else
    categories=struct('IHI10',struct('color','#0072B2'),'IHI40',struct('color','#009E73'), ...
      'Unconditioned',struct('color','#768495'),'Unknown',struct('color','#D55E00'));
  end
end

function class_boxes(out,samples)
  samples=samples(strcmp(samples(:,1),'IHI test'),:);
  if isempty(samples), return; end
  values=cell2mat(samples(:,7));
  codes={'IHI_10ms','IHI_40ms','Unconditioned_MEP','Unknown'};
  names={'IHI10','IHI40','Unconditioned','Unknown'};
  data={}; labels={};
  conditions=[{'All conditions'}; unique(samples(:,4))];
  for i=1:numel(conditions)
    box=struct; pick=true(size(values));
    if i>1, pick=strcmp(samples(:,4),conditions{i}); end
    for j=1:numel(codes)
      group=pick & strcmp(samples(:,6),codes{j});
      v=values(group & isfinite(values));
      if ~isempty(v), box.(sprintf('%s (n=%d/%d)',names{j},numel(v),sum(group)))=num2cell(v); end
    end
    if ~isempty(fieldnames(box)), data{end+1}=box; labels{end+1}=conditions{i}; end
  end
  if isempty(data), return; end
  config=struct('ylab','Right test MEP (mV)','sort_samples',false); config.data_labels=labels;
  content(out,'ihi','amplitudes','2 · Test MEP by class','box', ...
    ['Finite right test MEP amplitudes from actual IHI trials, pooled by detected class. Each label gives measured/total trials. ' ...
     'Use the tabs to select a condition. Classes describe detected stimulation intervals. No inhibition ratio is reported.'],config,data);
end

function rows=aggregate_ledger(aggregates,records)
  rows=cell(0,20);
  for i=1:size(aggregates,1)
    name=aggregates{i,1}; t=aggregates{i,2}; h=aggregates{i,3};
    src=struct('name',name,'values',{t},'header',h);
    ordinal=struct;
    for j=1:size(t,1)
      cl='';
      if strcmp(name,'CSP_results.tsv')
        module='CSP'; time=t{j,h.Time_Points};
        key=recording_key(module,t{j,h.ID},t{j,h.Visit},time);
        if ~isfield(ordinal,key), ordinal.(key)=0; end
        ordinal.(key)=ordinal.(key)+1; trial=ordinal.(key);
      elseif endsWith(name,'_IHI_Results.tsv')
        module='IHI'; time=t{j,h.Timepoint};
        key=recording_key(module,t{j,h.ID},t{j,h.Visit},time);
        trial=str2double(t{j,h.Trial}); cl=t{j,h.Condition};
      else
        continue;
      end
      padding=~isfield(records,key) || ~isfield(records.(key),module) || ...
        ~ismember(trial,number(records.(key).(module),'Trial'));
      rows(end+1,:)=ledger_row(src,j,module,module,key,trial,cl,padding);
    end
  end
end

function rows=ledger_rows(src,module,protocol,key,ids,classes,padding)
  if ischar(classes), classes=repmat({classes},numel(ids),1); end
  rows=cell(numel(ids),20);
  for i=1:numel(ids)
    rows(i,:)=ledger_row(src,i,module,protocol,key,ids(i),classes{i},padding(i));
  end
end

function row=ledger_row(src,i,module,protocol,key,trial,cl,padding)
  right=pick(src,i,{'MEP_Right_mV','MEP_mV','MEP (mV)'});
  left=pick(src,i,{'MEP_Left_mV','MEP_L (mV)'});
  csp=pick(src,i,{'CSP_v2_ms','CSP (ms)'});
  mn=pick(src,i,{'MEP_Norm (%)'}); cn=pick(src,i,{'CSP_Norm (%)'});
  bt=pick(src,i,{'Breakthrough','EMG_Breakthrough (yes/no)'});
  time=pick(src,i,{'Timepoint','Time_Points'});
  row={module,protocol,src.values{i,src.header.ID},src.values{i,src.header.Visit},time,trial,cl,right,left,csp,mn,cn,bt, ...
    pick(src,i,{'Status'}),pick(src,i,{'Test_Pulse_Index'}),pick(src,i,{'Conditioning_Pulse_Index'}),double(padding),src.name,i,key};
end

function value=pick(src,row,names)
  value='NA';
  for i=1:numel(names)
    name=names{i};
    if isfield(src.header,name), value=src.values{row,src.header.(name)}; return; end
  end
end

function write_qc(out,data)
  keys=fieldnames(data); fields=fieldnames(data.(keys{1}));
  rows=cell(numel(keys),4+numel(fields));
  for i=1:numel(keys)
    parts=strsplit(keys{i},' | ');
    rows(i,:)=[parts(1),{strrep(parts{2},'ID ','')},parts(3:4),struct2cell(data.(keys{i}))'];
  end
  write_tsv(fullfile(out,'recording_qc.tsv'),[{'Protocol','Participant','Condition','Timepoint'} fields'],rows);
end

function methods(out,p,run,enabled,versions_file,science_file)
  versions=strsplit(strtrim(fileread(versions_file)),sprintf('\n'));
  packages=pkg('list');
  packages=cellfun(@(x)[x.name ' ' x.version],packages,'UniformOutput',false);
  container='Native execution';
  if isfield(run,'container') && ~isempty(run.container), container=run.container; end
  correction='The left EMG 60 Hz correction was disabled.';
  if p.remove_60hz, correction='The left EMG was corrected by regressing 60 Hz sine and cosine terms before amplitude measurement.'; end
  s=sprintf(['<p><strong>MINT %s</strong> · Nextflow %s · %s · %s</p>' ...
    '<p>Modules: %s<br>Profile: %s<br>Container: <code>%s</code><br>Octave packages: %s</p>' ...
    '<details open><summary><strong>Methods for reporting</strong></summary>' ...
    '<p>LabChart EMG was sampled at %g Hz with %g samples per trial. MEP amplitude was measured peak-to-peak ' ...
    'using a window of ±%g ms about the selected centre. For CSP recordings, the historical detector uses discrete ' ...
    'differences and Savitzky–Golay smoothing. For IHI recordings, the search is referenced to the corresponding TMS pulse. %s</p>'], ...
    esc(run.mint),esc(run.nextflow),esc(version()),esc(versions{1}),esc(strjoin(upper(enabled),', ')), ...
    esc(run.profile),esc(container),esc(strjoin(packages,', ')),p.rate,p.samples_per_trial,p.mep_half_window_seconds*1000,correction);
  if ismember('csp',enabled)
    s=[s '<p>CSP v2 is the primary exported duration. It runs from the positive MEP peak in the original EMG to the first qualifying return ' ...
      'of sliding-window variability in the smoothed EMG difference above a baseline-derived threshold, with the historical breakthrough adjustment. The historical v1 ' ...
      'comparison and T0 normalisations are retained in the source tables. CSP duration is not specific to a single neurotransmitter pathway.</p>'];
  end
  if ismember('ihi',enabled)
    s=[s '<p>Test and conditioning indices were taken from the corresponding stimulation channels. ' ...
      'Absolute interpulse intervals within ±5 ms of 10 or 40 ms were classified as IHI10 or IHI40. ' ...
      'An absent conditioning pulse yields Unconditioned. Other intervals are Unknown. Classification describes detected timing.</p>'];
  end
  s=[s '<p>Amplitude changes may reflect several physiological and acquisition factors. The report provides descriptive summaries and QC flags.</p></details>'];
  s=[s '<details><summary><strong>Scientific parameters used</strong></summary><p>SHA-256: <code>' ...
     hash('sha256',fileread(science_file)) '</code></p><pre>' esc(fileread(science_file)) '</pre></details>'];
  content(out,'methods','run','Methods and reproducibility','html', ...
    'Versions and scientific settings for this run. Parameters shown below are the exact settings file staged with the report.',struct,s);
end

function s=esc(s)
  s=strrep(strrep(strrep(strrep(s,'&','&amp;'),'<','&lt;'),'>','&gt;'),'"','&quot;');
end

function key=recording_key(protocol,id,condition,time)
  key=[protocol ' | ID ' id ' | ' condition ' | ' time];
end

function values=number(src,col)
  values=cellfun(@str2double,src.values(:,src.header.(col)));
end

function content(out,section,id,name,kind,description,config,data,extras)
  parents=struct('overview','Overview','mep','MEP','csp','CSP','ihi','IHI','methods','Methods & Run Information');
  id=['tms_' section '_' id];
  config.id=[id '_plot']; config.title=name;
  payload=struct('id',id,'parent_id',['tms_' section],'parent_name',parents.(section), ...
    'section_name',name,'description',description,'plot_type',kind,'pconfig',config,'data',{data});
  if nargin==9
    for field=fieldnames(extras)', payload.(field{1})=extras.(field{1}); end
  end
  write_json(fullfile(out,[id '_mqc.json']),payload);
end

function [rows,header]=read_tsv(file)
  fid=fopen(file,'r'); assert(fid>=0,['Cannot read ' file]); cleanup=onCleanup(@()fclose(fid));
  line=fgetl(fid); assert(ischar(line),['Empty TSV: ' file]);
  fields=strsplit(line,sprintf('\t'),'collapsedelimiters',false);
  header=cell2struct(num2cell(1:numel(fields)),fields,2); rows=cell(0,numel(fields));
  while true
    line=fgetl(fid); if ~ischar(line), break; end
    if isempty(line), continue; end
    row=strsplit(line,sprintf('\t'),'collapsedelimiters',false);
    assert(numel(row)==numel(fields),['Inconsistent TSV width: ' file]);
    rows(end+1,:)=row;
  end
end

function write_json(file,value)
  fid=fopen(file,'w'); assert(fid>=0,['Cannot write ' file]); cleanup=onCleanup(@()fclose(fid));
  fprintf(fid,'%s\n',jsonencode(value));
end

function write_tsv(file,header,rows)
  fid=fopen(file,'w'); assert(fid>=0,['Cannot write ' file]); cleanup=onCleanup(@()fclose(fid));
  fprintf(fid,'%s\n',strjoin(header,sprintf('\t')));
  for i=1:size(rows,1)
    values=rows(i,:);
    for j=1:numel(values)
      if isnumeric(values{j})
        if isnan(values{j}), values{j}='NA'; else, values{j}=sprintf('%.17g',values{j}); end
      end
    end
    fprintf(fid,'%s\n',strjoin(values,sprintf('\t')));
  end
end
