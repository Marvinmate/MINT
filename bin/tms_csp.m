function tms_csp(features,settings)
  p=tms_init(settings); x=load(features); d=x.d;
  p=tms_record_params(p,d.rate,d.ends(1)-d.starts(1)+1);
  d.csp=nan(d.n,3); d.v1=nan(d.n,3); d.v2=nan(d.n,3); d.breakthrough=nan(d.n,1);
  d.csp_method=p.csp_end_method; d.parameters=p; rows=cell(d.n,15);
  for tr=1:d.n
    se=d.starts(tr):d.ends(tr); w=d.windows(tr,1):d.windows(tr,2);
    assert(w(1)-p.baseline_offset_samples-p.baseline_duration_samples>=se(1),'CSP baseline outside current trial');
    [v1,pk1,of1]=Calculate_CSP(d.raw,d.rate,se,w,p.csp_offset_samples,p.baseline_offset_samples,p.baseline_duration_samples,p.sliding_samples,p.threshold_fraction,p.sgolay_frame);
    d.v1(tr,:)=[v1 pk1 of1];
    if strcmp(p.csp_end_method,'breakthrough-aware')
      [bt,dur,peak,off]=Calculate_CSP_v2(p.breakthrough_max_samples,tr,d.time+1,{d.id},p.silence_samples,1,d.raw,d.rate,se,w,p.csp_offset_samples,p.baseline_offset_samples,p.baseline_duration_samples,p.sliding_samples,p.threshold_fraction,p.sgolay_frame);
      d.v2(tr,:)=[dur peak off]; d.csp(tr,:)=d.v2(tr,:); d.breakthrough(tr)=bt;
    else
      d.csp(tr,:)=d.v1(tr,:); % No breakthrough search; NaN means not evaluated.
    end
    rows(tr,:)={d.id,d.condition,['T' num2str(d.time)],tr,d.amp(tr,1)*1000,d.v2(tr,1)*1000,d.breakthrough(tr),d.csp(tr,2),d.v2(tr,3),v1*1000,of1,d.csp(tr,1)*1000,d.csp(tr,3),d.csp_method,d.included(tr)};
  end
  tms_write_tsv([d.key '.csp.tsv'],{'ID','Visit','Timepoint','Trial','MEP_mV','CSP_v2_ms','Breakthrough','CSP_Peak_Index','CSP_v2_Offset','CSP_v1_ms','CSP_v1_Offset','CSP_ms','CSP_Offset','CSP_Method','Included'},rows);
  save([d.key '.csp.mat'],'d','-v7');
end
