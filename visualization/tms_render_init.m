function r=tms_render_init(settings)
  r=jsondecode(fileread(settings));
  if ~isfield(r,'formats'), r.formats={'png','svg','pdf'}; end
  assert(iscell(r.formats) && ~isempty(r.formats),'Rendering formats must be a nonempty list');
  assert(all(ismember(r.formats,{'png','svg','pdf'})) && numel(unique(r.formats))==numel(r.formats),'Unsupported or duplicate rendering format');
  r.formats=reshape(r.formats,1,[]);
  assert(r.dpi>=72 && r.dpi<=1200 && r.dpi==round(r.dpi),'Invalid rendering DPI');
  assert(ismember(r.ihi_trials_per_page,6:12),'Use 6 to 12 trials per page');
  if exist('OCTAVE_VERSION','builtin')
    cache=fullfile(pwd,'.font-cache'); if ~exist(cache,'dir'), mkdir(cache); end
    setenv('XDG_CACHE_HOME',cache);
    warning('off','Octave:gnuplot-graphics'); graphics_toolkit('gnuplot');
  end
  set(0,'defaultfigurevisible','off','defaultaxesfontname',r.font,'defaulttextfontname',r.font,...
    'defaultaxesfontsize',r.font_size,'defaulttextfontsize',r.font_size,...
    'defaultaxeslinewidth',.7,'defaultlinelinewidth',r.line_width,...
    'defaultaxesbox','off','defaultaxestickdir','out','defaulttextinterpreter','none');
end
