function mint_plot_csv(figure_handle, base)
  % Serialize the visible series and annotations passed to the renderer.
  fid=fopen([base '.csv'],'w');
  assert(fid>=0,'Cannot open plot CSV');
  cleanup=onCleanup(@()fclose(fid));
  fprintf(fid,['panel,panel_title,x_label,y_label,kind,series,object,point,' ...
               'trial,x,y,coordinates,line_style,marker,color,text,value\r\n']);
  axes_list=flipud(findall(figure_handle,'type','axes'));
  for panel=1:numel(axes_list)
    ax=axes_list(panel);
    prefix=sprintf('%d,%s,%s,%s',panel,csv(get(get(ax,'Title'),'String')), ...
      csv(get(get(ax,'XLabel'),'String')),csv(get(get(ax,'YLabel'),'String')));
    fprintf(fid,'%s,panel,,,,,,,,,,,,\r\n',prefix);
    children=flipud(get(ax,'Children'));
    for index=1:numel(children)
      item=children(index);
      if ~strcmp(get(item,'Visible'),'on'), continue; end
      switch get(item,'Type')
        case 'line'
          style=get(item,'LineStyle'); marker=get(item,'Marker');
          if strcmp(style,'none') && strcmp(marker,'none'), continue; end
          x=get(item,'XData'); y=get(item,'YData');
          trial=getappdata(item,'mint_trials');
          if isempty(trial), trial=nan(size(x)); end
          if isscalar(trial), trial=repmat(trial,size(x)); end
          name=get(item,'DisplayName');
          leading=sprintf('%s,line,%s,%d,',prefix,csv(name),index);
          trailing=sprintf(',data,%s,%s,%s,,\r\n',csv(style),csv(marker),csv(rgb(get(item,'Color'))));
          format=[strrep(leading,'%','%%') '%d,%.17g,%.17g,%.17g' strrep(trailing,'%','%%')];
          fprintf(fid,format,[(1:numel(x)); trial(:)'; x(:)'; y(:)']);
        case 'text'
          label=get(item,'String'); position=get(item,'Position');
          if any(strcmp(label,{getappdata(figure_handle,'page_heading'),getappdata(figure_handle,'page_footer')})), continue; end
          value=getappdata(item,'mint_value');
          if ~isempty(value), value=sprintf('%.17g',value); else, value=''; end
          trial=getappdata(item,'mint_trials');
          if ~isempty(trial), trial=sprintf('%d',trial); else, trial=''; end
          fprintf(fid,'%s,text,,%d,,%s,%.17g,%.17g,%s,,,%s,%s,%s\r\n', ...
            prefix,index,trial,position(1),position(2),csv(get(item,'Units')),csv(rgb(get(item,'Color'))),csv(label),value);
      end
    end
  end
end

function field=csv(value)
  if iscell(value), value=strjoin(value,' '); end
  field=['"' strrep(value,'"','""') '"'];
end

function color=rgb(value)
  color=sprintf('#%02x%02x%02x',round(value*255));
end
