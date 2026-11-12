function tms_xlsx(filename,sheet,header,rows)
  content=[header;rows];
  for i=1:numel(content)
    if isnumeric(content{i}) && (isempty(content{i}) || isnan(content{i})), content{i}=''; end
  end
  if exist('OCTAVE_VERSION','builtin')
    pkg('load','io'); ok=xlswrite(filename,content,sheet,'A1','OCT'); assert(ok==1,'XLSX write failed');
  else
    writecell(content,filename,'Sheet',sheet);
  end
end
