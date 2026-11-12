function tms_write_json(filename,value)
  fid=fopen(filename,'w'); assert(fid>=0,'Cannot open JSON output');
  cleanup=onCleanup(@()fclose(fid)); fprintf(fid,'%s\n',jsonencode(value));
end
