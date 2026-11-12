function tms_ihi_export(files,settings)
  tms_init(settings); records=tms_load_records(files); id=records{1}.id;
  header={'ID','Visit','Timepoint','Trial','Condition','MEP_Right_mV','MEP_Left_mV'};
  allrows=cell(0,7); visits={'Full','Half','Pbo'};
  classOrder={'','IHI_10ms','IHI_40ms','Unconditioned_MEP','Unknown'};
  for v=1:3
    group=records(cellfun(@(d)strcmp(d.condition,visits{v}),records));
    if isempty(group), continue; end
    n=max(cellfun(@(d)d.n,group)); R=nan(n,6); L=R; C=repmat({''},n,6);
    for i=1:numel(group)
      d=group{i}; R(1:d.n,d.time+1)=d.amp(:,1); L(1:d.n,d.time+1)=d.amp(:,2); C(1:d.n,d.time+1)=d.classes;
    end
    R(R==0)=NaN; L(L==0)=NaN; rows=cell(n*6,7); keys=zeros(n*6,3); index=0;
    for tp=0:5
      for tr=1:n
        index=index+1; cl=C{tr,tp+1}; rank=find(strcmp(classOrder,cl)); assert(~isempty(rank),'Unknown class');
        rows(index,:)={id,visits{v},['T' num2str(tp)],tr,cl,R(tr,tp+1)*1000,L(tr,tp+1)*1000}; keys(index,:)=[tp rank tr];
      end
    end
    [~,order]=sortrows(keys,[1 2 3]); rows=rows(order,:); allrows=[allrows;rows];
    tms_xlsx([id '_IHI_Results.xlsx'],visits{v},header,rows);
  end
  tms_write_tsv([id '_IHI_Results.tsv'],header,allrows);
end
