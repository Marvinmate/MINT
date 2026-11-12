function p=tms_init(settings)
  if exist('OCTAVE_VERSION','builtin'), pkg('load','signal'); end
  p=jsondecode(fileread(settings));
  assert(p.rate==4000 && p.samples_per_trial==1600,'Historical algorithms require 4000 Hz and 1600 samples.');
end
