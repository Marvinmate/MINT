function test_synthetic(root,work)
  addpath(fullfile(root,'bin')); addpath(fullfile(root,'visualization'));
  settings=fullfile(root,'assets','scientific_params.json'); original=tms_init(settings);
  assert(~original.prestim_qc_enabled && ~original.prestim_qc_exclude);
  results=struct;
  for fs=[4000 1000]
    out=fullfile(work,sprintf('synthetic_%d',fs)); if ~exist(out,'dir'), mkdir(out); end; cd(out);
    p=original; p.prestim_qc_enabled=true; p.csp_stimulus_time_ms=100;
    tms_write_json('settings.json',p);
    for protocol={'CSP','IHI'}
      proto=protocol{1}; input=fullfile(root,'tests','fixtures',num2str(fs),proto,'sub-synthetic','Dose test',[proto '_T0.mat']);
      key=[proto '_synthetic_Baseline_T0'];
      tms_mep(input,'synthetic','Baseline',0,proto,key,'settings.json');
      x=load([key '.mep.mat']);d=x.d; assert(d.rate==fs); assert(all([d.qc.included]));
      assert(d.parameters.sgolay_frame==11 || (fs==1000 && d.parameters.sgolay_frame==5));
      if strcmp(proto,'IHI')
        tms_ihi([key '.mep.mat'],'settings.json');
        assert(isequal(d.classes,{'Unconditioned_MEP';'IHI_10ms';'IHI_40ms';'IHI_40ms'}));
        assert(d.ttl(1,1,1)==1+round(.100*fs));
        assert(d.ttl(1,1,2)==d.ttl(1,1,3) && d.stim(1,1)==d.ttl(1,1,2));
        assert(d.ttl(1,1,3)-d.ttl(1,1,1)+1==round(.005*fs));
        assert(d.search_windows(1,1,1)-d.stim(1,1)==round(.012*fs));
        assert(d.search_windows(1,1,2)-d.stim(1,1)==round(.060*fs));
        assert(d.qc(4).exceeded==1 && d.qc(4).included);
        p.prestim_qc_exclude=true; tms_write_json('exclude.json',p);
        tms_mep(input,'synthetic','Baseline',0,proto,'IHI_excluded','exclude.json');ex=load('IHI_excluded.mep.mat');
        assert(~ex.d.included(4) && isequaln(ex.d.amp,d.amp));
        p.prestim_qc_exclude=false;
        p.mep_search_start_ms=20;p.mep_search_end_ms=45;tms_write_json('search.json',p);
        tms_mep(input,'synthetic','Baseline',0,proto,'IHI_search','search.json');alt=load('IHI_search.mep.mat');
        assert(all(alt.d.search_windows(2,:,1)-alt.d.stim(2,:)==round(.020*fs)));
        assert(all(alt.d.search_windows(2,:,2)-alt.d.stim(2,:)==round(.045*fs)));
        p.mep_search_start_ms=12;p.mep_search_end_ms=60;
        results.(sprintf('ihi_%d',fs))=struct('classes',{d.classes},'amplitudes_mV',d.amp*1000,'ttl',d.ttl,'qc',{d.qc});
      else
        tms_csp([key '.mep.mat'],'settings.json');x=load([key '.csp.mat']);main=x.d;
        assert(all(main.breakthrough([1 3])==0));assert(all(main.breakthrough([2 4])==1));
        assert(all(main.csp([2 4],1)>main.v1([2 4],1)));
        p.csp_end_method='standard'; tms_write_json('standard.json',p);tms_csp([key '.mep.mat'],'standard.json'); x=load([key '.csp.mat']);
        assert(isequaln(x.d.csp,main.v1));assert(all(isnan(x.d.v2(:))));assert(all(isnan(x.d.breakthrough)));
        p.csp_end_method='breakthrough-aware'; tms_csp([key '.mep.mat'],'settings.json');
        results.(sprintf('csp_%d',fs))=struct('main_ms',main.csp(:,1)*1000,'standard_ms',main.v1(:,1)*1000,'breakthrough',main.breakthrough);
      end
    end
    % Negative cases: invalid windows, missing reference and unavailable baseline remain distinct.
    p=original;p.mep_search_start_ms=60;p.mep_search_end_ms=12;tms_write_json('invalid.json',p);
    failed=false;try,tms_init('invalid.json');catch,failed=true;end;assert(failed);
    p=original;p.prestim_qc_enabled=true;
    q=tms_prestim_qc(zeros(100,1),NaN,fs,p);assert(strcmp(q.status,'MissingReference') && isnan(q.exceeded));
    q=tms_prestim_qc(zeros(100,1),2,fs,p);assert(strcmp(q.status,'UnavailableWindow'));
    p.prestim_start_ms=-20;p.prestim_end_ms=-5;
    q=tms_prestim_qc(zeros(round(.1*fs),1),round(.05*fs),fs,p);assert(q.value_uv==0 && q.exceeded==0);
    % End-of-trial IHI search: no out-of-bounds access; missing measurement is explicit.
    [amp,centre]=measure_MEP(zeros(100,1),105,120,fs,.01);assert(isnan(amp) && isnan(centre));
  end
  assert(max(abs(results.csp_4000.main_ms-results.csp_1000.main_ms))<6);
  tms_write_json(fullfile(work,'synthetic_tests.json'),results);
  fprintf('PASS: synthetic 1000/4000 Hz, TTL indices, CSP modes, QC, invalid settings\n');
end
