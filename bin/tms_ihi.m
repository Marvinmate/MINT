function tms_ihi(features,settings)
  tms_init(settings); x=load(features); d=x.d;
  rows=cell(d.n,17);
  for tr=1:d.n
    d.classes{tr}=tms_ihi_condition(d.stim(tr,1),d.stim(tr,2),d.rate);
    rows(tr,:)={d.id,d.condition,['T' num2str(d.time)],tr,d.classes{tr},d.amp(tr,1)*1000,d.amp(tr,2)*1000,d.stim(tr,1),d.stim(tr,2),d.ttl(tr,1,1),d.ttl(tr,1,3),d.ttl(tr,1,4),d.ttl(tr,2,1),d.ttl(tr,2,3),d.ttl(tr,2,4),abs(diff(d.stim(tr,:)))*1000/d.rate,d.included(tr)};
  end
  tms_write_tsv([d.key '.ihi.tsv'],{'ID','Visit','Timepoint','Trial','Condition','MEP_Right_mV','MEP_Left_mV','Test_Pulse_Index','Conditioning_Pulse_Index','Test_TTL_Start','Test_TTL_End','Test_TTL_Duration_ms','Conditioning_TTL_Start','Conditioning_TTL_End','Conditioning_TTL_Duration_ms','ISI_ms','Included'},rows);
  save([d.key '.ihi.mat'],'d','-v7');
end
