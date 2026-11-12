function tms_write_tsv(filename,header,rows)
  fid=fopen(filename,'w'); assert(fid>=0,'Cannot open TSV output');
  cleanup=onCleanup(@()fclose(fid));
  all=[header;rows];
  for i=1:size(all,1)
    for j=1:size(all,2)
      if j>1, fprintf(fid,'\t'); end
      x=all{i,j};
      if isnumeric(x)||islogical(x)
        if isempty(x)||isnan(x), fprintf(fid,'NA'); else, fprintf(fid,'%.17g',double(x)); end
      else, fprintf(fid,'%s',char(x)); end
    end
    fprintf(fid,'\n');
  end
end
