function records=tms_load_records(files)
  records=cell(size(files));
  for i=1:numel(files), x=load(files{i}); records{i}=x.d; end
end
