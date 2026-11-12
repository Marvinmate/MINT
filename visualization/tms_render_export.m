function tms_render_export(f,base,r)
  if isfield(r,'export_csv') && r.export_csv, mint_plot_csv(f,base); end
  formats={'svg','pdf','png'}; formats=formats(ismember(formats,r.formats));
  if ~exist('OCTAVE_VERSION','builtin')
    for item=formats
      fmt=item{1};
      if strcmp(fmt,'png'), print(f,[base '.png'],'-dpng',['-r' num2str(r.dpi)]);
      else, print(f,[base '.' fmt],['-d' fmt],'-painters'); end
    end
    return;
  end
  % Batch gnuplot avoids Octave's synchronous FIFO queries, which can hang
  % on macOS during large multipanel exports. Serialize existing graphics
  % objects only: no scientific values or events are calculated here.
  gp=[base '.render.gp']; fid=fopen(gp,'w'); assert(fid>=0);
  fprintf(fid,'set encoding utf8\n');
  axesList=flipud(findall(f,'type','axes')); panels=cell(1,numel(axesList)); counter=0;
  for a=1:numel(axesList)
    ax=axesList(a); children=flipud(get(ax,'Children')); lines={}; labels={};
    for j=1:numel(children)
      h=children(j); type=get(h,'Type');
      if strcmp(type,'line') && strcmp(get(h,'Visible'),'on')
        counter=counter+1; name=sprintf('$D%d',counter);
        x=get(h,'XData'); y=get(h,'YData'); data=[x(:),y(:)];
        fprintf(fid,'%s << TMS_DATA_END\n',name); fprintf(fid,'%.17g %.17g\n',data'); fprintf(fid,'TMS_DATA_END\n');
        lines{end+1}=struct('name',name,'color',get(h,'Color'),'width',get(h,'LineWidth'),'style',get(h,'LineStyle'),'marker',get(h,'Marker'),'size',get(h,'MarkerSize'));
      elseif strcmp(type,'text') && strcmp(get(h,'Visible'),'on')
        str=get(h,'String'); if iscell(str), str=strjoin(str,' '); end
        if strcmp(str,getappdata(f,'page_heading')) || strcmp(str,getappdata(f,'page_footer')), continue; end
        labels{end+1}=struct('str',str,'pos',get(h,'Position'),'units',get(h,'Units'),'size',get(h,'FontSize'),'color',get(h,'Color'),'align',get(h,'HorizontalAlignment'));
      end
    end
    panels{a}=struct('ax',ax,'lines',{lines},'labels',{labels});
  end
  inches=get(f,'PaperSize');
  for fmt=formats
    fmt=fmt{1}; scale=1;
    fprintf(fid,'reset\nset encoding utf8\nunset key\n');
    if strcmp(fmt,'png')
      scale=r.dpi/72; pixels=round(inches*r.dpi);
      fprintf(fid,'set terminal pngcairo noenhanced fontscale 0.75 size %d,%d font %s linewidth %.10g\n',pixels,qt(sprintf('%s,%.10g',r.font,r.font_size*scale)),scale);
    elseif strcmp(fmt,'pdf')
      fprintf(fid,'set terminal pdfcairo noenhanced fontscale 0.75 size %.10gin,%.10gin font %s\n',inches,qt(sprintf('%s,%g',r.font,r.font_size)));
    else
      fprintf(fid,'set terminal svg noenhanced linewidth 0.5 size %.10g,%.10g font %s\n',inches*72,qt(sprintf('%s,%g',r.font,r.font_size)));
    end
    fprintf(fid,'set output %s\nset multiplot\n',qt([base '.' fmt]));
    for a=1:numel(panels)
      panel=panels{a}; ax=panel.ax; pos=get(ax,'Position'); fs=get(ax,'FontSize')*scale;
      fprintf(fid,'unset label\nunset arrow\nunset object\nunset grid\nset border 3 lc rgb "#444444" lw 0.7\n');
      fprintf(fid,'set lmargin at screen %.12g\nset rmargin at screen %.12g\nset bmargin at screen %.12g\nset tmargin at screen %.12g\n',pos(1),pos(1)+pos(3),pos(2),pos(2)+pos(4));
      fprintf(fid,'set xrange [%.17g:%.17g]\nset yrange [%.17g:%.17g]\n',get(ax,'XLim'),get(ax,'YLim'));
      ticks(fid,'x',get(ax,'XTick'),get(ax,'XTickLabel'),r.font,fs); ticks(fid,'y',get(ax,'YTick'),get(ax,'YTickLabel'),r.font,fs);
      text_property(fid,'xlabel',get(ax,'XLabel'),r.font,scale); text_property(fid,'ylabel',get(ax,'YLabel'),r.font,scale); text_property(fid,'title',get(ax,'Title'),r.font,scale);
      label=0;
      for j=1:numel(panel.labels)
        z=panel.labels{j}; label=label+1; coord='first'; xy=z.pos(1:2);
        if strcmp(z.units,'normalized'), coord='graph'; end
        align=z.align; if strcmp(align,'center'), align='center'; elseif strcmp(align,'right'), align='right'; else, align='left'; end
        fprintf(fid,'set label %d %s at %s %.17g,%.17g %s front font %s tc rgb %s\n',label,qt(z.str),coord,xy,align,qt(sprintf('%s,%g',r.font,z.size*scale)),qt(rgb(z.color)));
      end
      if a==1
        label=label+1;
        fprintf(fid,'set label %d %s at screen 0.06,0.966 left front font %s\n',label,qt(getappdata(f,'page_heading')),qt(sprintf('%s:Bold,%g',r.font,(r.font_size+3)*scale)));
        fprintf(fid,'set label %d %s at screen 0.06,0.028 left front font %s\n',label+1,qt(getappdata(f,'page_footer')),qt(sprintf('%s,%g',r.font,8*scale)));
      end
      commands={};
      for j=1:numel(panel.lines)
        z=panel.lines{j}; style='lines'; marker=''; dash=1;
        if strcmp(z.style,'--'), dash=2; elseif strcmp(z.style,':'), dash=3; end
        if ~strcmp(z.marker,'none')
          style='linespoints'; if strcmp(z.style,'none'), style='points'; end
          marker=sprintf(' pt 6 ps %.10g',z.size/6*scale);
        elseif strcmp(z.style,'none'), continue; end
        commands{end+1}=sprintf('%s using 1:2 with %s lc rgb %s lw %.10g dt %d%s notitle',z.name,style,qt(rgb(z.color)),z.width,dash,marker);
      end
      if isempty(commands)
        fprintf(fid,'plot NaN notitle\n');
      else
        % Keep physical command lines short for recordings with 60+ traces.
        fprintf(fid,'plot %s\n',strjoin(commands,{[', ' char(92) char(10)]}));
      end
    end
    fprintf(fid,'unset multiplot\nunset output\n');
  end
  fclose(fid);
  [status,message]=system(['gnuplot ' shellquote(gp)]); assert(status==0,['gnuplot batch failed: ' message]);
  if any(strcmp(formats,'svg'))
  svg=fileread([base '.svg']); svg=strrep(svg,['font-family="' r.font ':Bold"'],['font-family="' r.font '" font-weight="bold"']);
  fid=fopen([base '.svg'],'w'); assert(fid>=0); fprintf(fid,'%s',svg); fclose(fid);
  end
  if any(strcmp(formats,'png')), png_resolution([base '.png'],r.dpi); end
  delete(gp);
end
function ticks(fid,axis,values,labels,font,size)
  if ischar(labels), labels=cellstr(labels); end
  entries=cell(1,numel(values));
  for j=1:numel(values)
    label=sprintf('%g',values(j)); if j<=numel(labels), label=labels{j}; end
    entries{j}=sprintf('%s %.17g',qt(strtrim(label)),values(j));
  end
  fprintf(fid,'set %stics out nomirror font %s (%s)\n',axis,qt(sprintf('%s,%g',font,size)),strjoin(entries,','));
end
function text_property(fid,name,h,font,scale)
  str=get(h,'String'); if iscell(str), str=strjoin(str,' '); end
  if strcmp(get(h,'FontWeight'),'bold'), font=[font ':Bold']; end
  fprintf(fid,'set %s %s font %s\n',name,qt(str),qt(sprintf('%s,%g',font,get(h,'FontSize')*scale)));
end
function s=qt(s), s=['"' strrep(strrep(s,'\','\\'),'"','\"') '"']; end
function s=shellquote(s), s=['''' strrep(s,'''','''"''"''') '''']; end
function s=rgb(c), s=sprintf('#%02x%02x%02x',round(c*255)); end
function png_resolution(file,dpi)
  % Insert standard PNG physical-pixel-size metadata; image pixels untouched.
  fid=fopen(file,'rb'); bytes=fread(fid,Inf,'*uint8')'; fclose(fid);
  payload=[uint8('pHYs') u32(round(dpi/.0254)) u32(round(dpi/.0254)) uint8(1)];
  crc=uint32(hex2dec('FFFFFFFF'));
  for b=payload
    crc=bitxor(crc,uint32(b));
    for k=1:8
      if bitand(crc,1), crc=bitxor(bitshift(crc,-1),uint32(hex2dec('EDB88320'))); else, crc=bitshift(crc,-1); end
    end
  end
  chunk=[u32(9) payload u32(bitxor(crc,uint32(hex2dec('FFFFFFFF'))))];
  output=bytes(1:8); pos=9;
  while pos<=numel(bytes)
    n=double(bytes(pos:pos+3))*[16777216;65536;256;1]; type=char(bytes(pos+4:pos+7));
    if ~strcmp(type,'pHYs'), output=[output bytes(pos:pos+n+11)]; end
    if strcmp(type,'IHDR'), output=[output chunk]; end
    pos=pos+n+12;
  end
  fid=fopen(file,'wb'); assert(fid>=0); fwrite(fid,output,'uint8'); fclose(fid);
end
function b=u32(v), v=uint32(v); b=uint8([bitshift(v,-24),bitand(bitshift(v,-16),255),bitand(bitshift(v,-8),255),bitand(v,255)]); end
