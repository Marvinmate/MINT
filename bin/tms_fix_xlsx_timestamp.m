function tms_fix_xlsx_timestamp(filename)
  % Octave io 2.7.2 rounds seconds and can emit :60Z in core.xml.
  % Clamp the rounded value back to its actual second within the minute.
  filename=make_absolute_filename(filename);
  scratch=tempname(fileparts(filename));
  mkdir(scratch);
  cleanup=onCleanup(@()rmdir(scratch,'s'));
  contents=fullfile(scratch,'contents');
  unzip(filename,contents);
  core=fullfile(contents,'docProps','core.xml');
  if ~isfile(core), return; end
  xml=fileread(core);
  fixed=regexprep(xml,'(T[0-9]{2}:[0-9]{2}):60Z(?=</dcterms:(created|modified)>)','$1:59Z');
  if strcmp(xml,fixed), return; end
  fid=fopen(core,'wb');
  assert(fid>=0,'Cannot update XLSX timestamp');
  written=fwrite(fid,fixed,'char');
  closed=fclose(fid);
  assert(written==numel(fixed) && closed==0,'Cannot write XLSX timestamp');
  repaired=fullfile(scratch,'repaired.zip');
  zip(repaired,'*',contents);
  [ok,message]=movefile(repaired,filename,'f');
  assert(ok,message);
end
