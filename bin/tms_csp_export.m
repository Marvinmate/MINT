function tms_csp_export(files,settings)
  tms_init(settings); records=tms_load_records(files);
  ids=sort(unique(cellfun(@(d)d.id,records,'UniformOutput',false))); visits={'Full','Half','Pbo'};
  rows=cell(0,8);
  for p=1:numel(ids)
    A=struct;
    for v=1:3
      group=records(cellfun(@(d)strcmp(d.id,ids{p})&&strcmp(d.condition,visits{v}),records));
      if isempty(group), M=nan(0,6); C=M; else
        n=max(cellfun(@(d)d.n,group)); M=nan(n,6); C=M;
        for i=1:numel(group), d=group{i}; M(1:d.n,d.time+1)=d.amp(:,1); C(1:d.n,d.time+1)=d.csp(:,1); end
      end
      M(M==0)=NaN; C(C==0)=NaN;
      A.(['MEP' num2str(v)])=M; A.(['CSP_Duration' num2str(v)])=C;
    end
    A=Norm_to_T0(A);
    for v=1:3
      M=A.(['MEP' num2str(v)]); C=A.(['CSP_Duration' num2str(v)]);
      if isempty(M), continue; end
      MN=A.(['MEP' num2str(v) '_Norm']); CN=A.(['CSP' num2str(v) '_Norm']);
      B=zeros(size(M));
      group=records(cellfun(@(d)strcmp(d.id,ids{p})&&strcmp(d.condition,visits{v}),records));
      for i=1:numel(group), d=group{i}; B(1:d.n,d.time+1)=d.breakthrough; end
      for tp=0:5
        for tr=1:size(M,1)
          rows(end+1,:)={ids{p},visits{v},['T' num2str(tp)],M(tr,tp+1)*1000,C(tr,tp+1)*1000,MN(tr,tp+1)*100,CN(tr,tp+1)*100,B(tr,tp+1)};
        end
      end
    end
  end
  header={'ID','Visit','Time_Points','MEP (mV)','CSP (ms)','MEP_Norm (%)','CSP_Norm (%)','EMG_Breakthrough (yes/no)'};
  tms_write_tsv('CSP_results.tsv',header,rows);
  tms_xlsx(['ID_' strjoin(ids,'_') '.xlsx'],'Sheet1',header,rows);
end
