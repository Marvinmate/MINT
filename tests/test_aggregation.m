function test_aggregation(root,work)
  addpath(fullfile(root,'bin')); settings=fullfile(root,'assets','scientific_params.json');
  out=fullfile(work,'aggregation_tests'); if ~exist(out,'dir'), mkdir(out); end; cd(out);
  x=load(fullfile(work,'synthetic_1000','CSP_synthetic_Baseline_T0.csp.mat')); base=x.d;
  files={}; labels={'v1','v2','v3','Dose haute'};
  for k=1:numel(labels)
    for time=0:1
      d=base;d.condition=labels{k};d.time=time;d.csp=d.v1;d.csp(:,1)=d.csp(:,1)*(time+1);d.csp_method='standard';d.breakthrough=nan(d.n,1);d.included=[true;false;true;true];
      name=sprintf('condition%d_T%d.csp.mat',k,time);save(name,'d','-v7');files{end+1}=name;
    end
  end
  tms_csp_export(files,settings);
  fid=fopen('CSP_results.tsv');header=strsplit(fgetl(fid),sprintf('\t')); rows={};
  while true, line=fgetl(fid);if ~ischar(line),break;end;rows(end+1,:)=strsplit(line,sprintf('\t'));end;fclose(fid);
  for k=1:numel(labels)
    mask=strcmp(rows(:,2),labels{k});subset=rows(mask,:);
    t1=subset(strcmp(subset(:,3),'T1'),:);
    expected=base.v1(:,1)*2/mean(base.v1([1 3 4],1))*100;
    assert(strcmp(t1{2,7},'NA'));
    for tr=[1 3 4],assert(abs(str2double(t1{tr,7})-expected(tr))<1e-10);end
    t0=subset(strcmp(subset(:,3),'T0'),:);assert(strcmp(t0{2,7},'NA'));
  end
  pkg load signal;
  [bt,dur,peak,off]=Calculate_CSP_v2(160,1,1,{'synthetic'},60,1,zeros(1,1600),4000,1:1600,450:500,120,80,200,20,.25);
  assert(~bt && isnan(dur) && isnan(off));
  fprintf('PASS: 4 conditions, selected standard CSP normalisation, excluded T0 and no-return CSP\n');
end
