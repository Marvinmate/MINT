% Run from an external writable directory with Octave.
root=fileparts(fileparts(mfilename('fullpath')));
work=pwd;
assert(~strcmp(work,root) && ~strncmp(work,[root filesep],length(root)+1), ...
  'Run from an output directory outside the distribution');
addpath(fullfile(root,'tests'));
test_synthetic(root,work);
test_aggregation(root,work);
cd(work);
test_xlsx_timestamp();
