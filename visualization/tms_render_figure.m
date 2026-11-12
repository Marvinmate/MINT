function f=tms_render_figure(inches,heading,footer,r)
  f=figure('Visible','off','Color','w','Units','pixels','Position',[1 1 inches(:)'*96]);
  if exist('OCTAVE_VERSION','builtin'), graphics_toolkit(f,'gnuplot'); end
  set(f,'PaperUnits','inches','PaperPosition',[0 0 inches(:)'],'PaperSize',inches(:)', 'PaperPositionMode','manual','InvertHardcopy','off');
  setappdata(f,'page_heading',heading); setappdata(f,'page_footer',footer);
end
