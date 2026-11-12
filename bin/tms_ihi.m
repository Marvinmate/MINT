function tms_ihi(features,settings)
  tms_init(settings); x=load(features); d=x.d;
  rows=cell(d.n,9);
  for tr=1:d.n
    d.classes{tr}=tms_ihi_condition(d.stim(tr,1),d.stim(tr,2),d.rate);
    rows(tr,:)={d.id,d.condition,['T' num2str(d.time)],tr,d.classes{tr},d.amp(tr,1)*1000,d.amp(tr,2)*1000,d.stim(tr,1),d.stim(tr,2)};
  end
  tms_write_tsv([d.key '.ihi.tsv'],{'ID','Visit','Timepoint','Trial','Condition','MEP_Right_mV','MEP_Left_mV','Test_Pulse_Index','Conditioning_Pulse_Index'},rows);
  save([d.key '.ihi.mat'],'d','-v7');
end
