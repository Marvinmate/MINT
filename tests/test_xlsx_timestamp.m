function test_xlsx_timestamp()
  tms_xlsx('timestamp.xlsx','Test',{'label','value'},{'synthetic',1.25});
  xlsx=fullfile(pwd,'timestamp.xlsx');
  unzip(xlsx,'before');
  core=fullfile('before','docProps','core.xml');
  xml=fileread(core);
  injected=regexprep(xml,'(T[0-9]{2}:[0-9]{2}):[0-9]{2}Z(?=</dcterms:(created|modified)>)','$1:60Z');
  assert(numel(strfind(injected,':60Z'))==2);
  fid=fopen(core,'wb');
  assert(fid>=0);
  fwrite(fid,injected,'char');
  fclose(fid);
  zip(fullfile(pwd,'invalid.zip'),'*',fullfile(pwd,'before'));
  movefile('invalid.zip',xlsx,'f');

  tms_fix_xlsx_timestamp(xlsx);
  unzip(xlsx,'after');
  fixed=fileread(fullfile('after','docProps','core.xml'));
  assert(strcmp(fixed,strrep(injected,':60Z',':59Z')));
  worksheet=fullfile('xl','worksheets','sheet1.xml');
  assert(strcmp(fileread(fullfile('before',worksheet)),fileread(fullfile('after',worksheet))));
  [~,~,cells]=xlsread(xlsx,'Test','A1:B2','OCT');
  assert(isequal(cells,{'label','value';'synthetic',1.25}));
  fprintf('PASS: invalid XLSX timestamps repaired, worksheet unchanged\n');
end
