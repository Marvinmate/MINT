function tms_csp_duration_render(records,order,p,r)
  % Durations are copied from scientific outputs; only descriptive means here.
  times=sort(unique(cellfun(@(d)d.time,records)));
  palette=[0 .447 .698;.835 .369 0;0 .62 .45;.8 .47 .65;.9 .62 0;.34 .71 .91];
  colors=palette(1+mod(0:numel(order)-1,size(palette,1)),:);
  durations=cellfun(@(d)d.csp(:,1)*1000,records,'UniformOutput',false);
  sharedLimits=tms_render_limits(vertcat(durations{:}));
  % Keep rounded tick labels distinct for identical or nearly identical durations.
  if diff(sharedLimits)<2
    sharedLimits=mean(sharedLimits)+[-1 1];
  end
  for page=1:ceil(numel(order)/3)
    indices=(page-1)*3+1:min(page*3,numel(order)); count=numel(indices);
    inches=[11 max(4,3*count)];
    f=tms_render_figure(inches,sprintf('CSP duration | ID %s | %s',records{1}.id,p.csp_end_method),...
      'Dots: stored trial durations | Lines: means of included trials | Red crosses: excluded trials | Absolute durations, not percentages',r);
    audit=cell(1,count);
    for panel=1:count
      k=indices(panel); ax=tms_render_axes(f,[.10 .91-panel*.82/count+.12/count .84 .47/count],r);
      means=nan(size(times)); plotted=cell(1,numel(times)); allvalues=[];
      for j=1:numel(times)
        subset=records(cellfun(@(d)strcmp(d.condition,order{k}) && d.time==times(j),records));
        if isempty(subset), continue; end
        d=subset{1}; y=d.csp(:,1)*1000; included=true(d.n,1); if isfield(d,'included'), included=d.included; end
        assert(~isfield(d,'csp_method') || strcmp(d.csp_method,p.csp_end_method),'CSP method mismatch');
        spread=zeros(d.n,1); if d.n>1, spread=linspace(-.15,.15,d.n)'; end
        for state=[true false]
          pick=find(included==state & isfinite(y)); if isempty(pick), continue; end
          marker='o'; color=colors(k,:); name='Included trial'; if ~state, marker='x'; color=[.8 .15 .1]; name='Excluded trial'; end
          h=plot(ax,j+spread(pick),y(pick),marker,'Color',color,'MarkerSize',3,'LineStyle','none','DisplayName',name);
          setappdata(h,'mint_trials',pick); drawn=get(h,'YData'); assert(isequal(drawn(:),y(pick)),'Duration values differ from scientific output');
        end
        finite=y(included & isfinite(y)); if ~isempty(finite), means(j)=mean(finite); end
        allvalues=[allvalues;y(isfinite(y))];
        plotted{j}=struct('time',times(j),'durations_ms',y,'included',included,'mean_ms',means(j));
      end
      if isempty(allvalues), plot(ax,NaN,NaN); end
      ylim(ax,sharedLimits);
      plot(ax,1:numel(times),means,'s-','MarkerSize',4,'LineWidth',.8,'Color',colors(k,:),'DisplayName','Included mean');
      set(ax,'XLim',[.5 numel(times)+.5],'XTick',1:numel(times),'XTickLabel',arrayfun(@(t)sprintf('T%d',t),times,'UniformOutput',false));
      ylabel(ax,'CSP duration (ms)'); xlabel(ax,'Acquisition'); title(ax,order{k},'FontWeight','bold');
      audit{panel}=struct('condition',order{k},'acquisitions',{plotted});
    end
    base=sprintf('%s.csp_durations_p%02d',records{1}.id,page);tms_render_export(f,base,r);close(f);
    tms_write_json([base '.render.json'],struct('method',p.csp_end_method,'units','ms','axes',{audit},'dpi',300));
  end
end
