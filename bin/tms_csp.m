function tms_csp(features,settings)
  p=tms_init(settings); x=load(features); d=x.d;
  d.csp=nan(d.n,3); d.v1=nan(d.n,3); d.breakthrough=false(d.n,1);
  rows=cell(d.n,11);
  for tr=1:d.n
    se=d.starts(tr):d.ends(tr); w=d.windows(tr,1):d.windows(tr,2);
    [bt,dur,peak,off]=Calculate_CSP_v2(p.breakthrough_max_samples,tr,d.time+1,{d.id},p.silence_samples,1,d.raw,p.rate,se,w,p.csp_offset_samples,p.baseline_offset_samples,p.baseline_duration_samples,p.sliding_samples,p.threshold_fraction);
    [v1,pk1,of1]=Calculate_CSP(d.raw,p.rate,se,w,p.csp_offset_samples,p.baseline_offset_samples,p.baseline_duration_samples,p.sliding_samples,p.threshold_fraction);
    d.csp(tr,:)=[dur peak off]; d.v1(tr,:)=[v1 pk1 of1]; d.breakthrough(tr)=bt;
    rows(tr,:)={d.id,d.condition,['T' num2str(d.time)],tr,d.amp(tr,1)*1000,dur*1000,bt,peak,off,v1*1000,of1};
  end
  tms_write_tsv([d.key '.csp.tsv'],{'ID','Visit','Timepoint','Trial','MEP_mV','CSP_v2_ms','Breakthrough','CSP_Peak_Index','CSP_v2_Offset','CSP_v1_ms','CSP_v1_Offset'},rows);
  save([d.key '.csp.mat'],'d','-v7');
end
