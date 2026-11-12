function ax=tms_render_axes(f,pos,r)
  first=isempty(findall(f,'type','axes'));
  ax=axes('Parent',f,'Position',pos,'FontSize',r.font_size,'FontName',r.font, 'LineWidth',.7,'Box','off','TickDir','out','Layer','top'); hold(ax,'on');
  if first
    text(ax,(.06-pos(1))/pos(3),(.974-pos(2))/pos(4),getappdata(f,'page_heading'),'Units','normalized','Clipping','off','FontSize',r.font_size+3,'FontWeight','bold','VerticalAlignment','top');
    text(ax,(.06-pos(1))/pos(3),(.025-pos(2))/pos(4),getappdata(f,'page_footer'),'Units','normalized','Clipping','off','FontSize',8,'VerticalAlignment','bottom');
  end
end
