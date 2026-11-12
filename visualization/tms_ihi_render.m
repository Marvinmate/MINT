function tms_ihi_render(record,settings,slim)
  if nargin<3, slim=false; end
  r=tms_render_init(settings); x=load(record); d=x.d;
  if slim, r.formats={'png'}; r.export_csv=true; end
  classes={'Unconditioned_MEP','IHI_10ms','IHI_40ms'};
  names={'Unconditioned','IHI10','IHI40'};
  colors=[.20 .39 .65; .05 .52 .40; .56 .29 .65];
  channelColors=[.05 .32 .62; .78 .26 .12]; channelNames={'Right','Left'};
  t=(0:size(d.trials,1)-1)*1000/d.rate; counts=zeros(1,3);
  footer='New visualization | All individual raw traces | Classifications and event indices copied from validated outputs';
  f=tms_render_figure(r.ihi_overview_inches,['IHI | ' d.key ' | All trials'],footer,r);
  for ch=1:2
    lim=tms_render_limits(d.trials(:,ch,:)*1000);
    for cl=1:3
      ix=find(strcmp(d.classes,classes{cl})); counts(cl)=numel(ix);
      ax=tms_render_axes(f,[.085+(ch-1)*.49 .72-(cl-1)*.29 .385 .18],r);
      for tr=ix(:)'
        h=plot(ax,t,d.trials(:,ch,tr)*1000,'Color',.45+.55*colors(cl,:),'LineWidth',.6,'DisplayName',[channelNames{ch} ' raw EMG']);
        setappdata(h,'mint_trials',tr);
        drawn=get(h,'YData'); assert(isequal(drawn(:),d.trials(:,ch,tr)*1000),'Rendered raw trace differs');
      end
      ylim(ax,lim); xlim(ax,[0 t(end)]); set(ax,'XTick',0:100:400);
      xlabel(ax,'Time (ms)'); ylabel(ax,'Raw EMG (mV)');
      title(ax,sprintf('%s | %s | n = %d',names{cl},channelNames{ch},numel(ix)),'FontSize',11,'FontWeight','bold');
      if isempty(ix)
        % A white background polygon avoids gnuplot's empty-axes inline-data
        % fallback. It is a graphical background, never a measurement.
        patch(ax,[0 t(end) t(end) 0],lim([1 1 2 2]),'w','EdgeColor','none');
        text(ax,.5,.5,'No trials','Units','normalized','HorizontalAlignment','center');
      end
    end
  end
  tms_render_export(f,[d.key '.ihi_overview'],r); close(f);
  % Per-channel amplitudes remain separate; each point is one stored value.
  f=tms_render_figure(r.ihi_summary_inches,['IHI | ' d.key ' | Stored MEP amplitudes'],...
    'New visualization | Dots: individual stored values, deterministic horizontal spread | Left: historical 60 Hz correction; unconditioned not measured',r);
  finiteCounts=zeros(2,3); plotted=cell(2,3);
  for ch=1:2
    ax=tms_render_axes(f,[.09+(ch-1)*.49 .22 .38 .59],r); labels=cell(1,3);
    for cl=1:3
      ix=find(strcmp(d.classes,classes{cl}) & isfinite(d.amp(:,ch)));
      y=d.amp(ix,ch)*1000; n=numel(y); finiteCounts(ch,cl)=n;
      spread=zeros(n,1); if n>1, spread=linspace(-.17,.17,n)'; end
      drawn=[]; if n>0, h=plot(ax,cl+spread,y,'o','Color',colors(cl,:),'MarkerSize',4,'MarkerFaceColor','w','DisplayName',names{cl}); setappdata(h,'mint_trials',ix); drawn=get(h,'YData'); end
      assert(isequal(drawn(:),y(:)),'Rendered amplitudes differ');
      plotted{ch,cl}=struct('trials',ix,'values_mV',drawn(:));
      labels{cl}=sprintf('%s (n=%d)',names{cl},n);
    end
    if ~any(finiteCounts(ch,:))
      patch(ax,[.5 3.5 3.5 .5],[0 0 1 1],'w','EdgeColor','none'); ylim(ax,[0 1]);
      text(ax,.5,.5,'Not measured','Units','normalized','HorizontalAlignment','center');
    end
    set(ax,'XLim',[.5 3.5],'XTick',1:3,'XTickLabel',labels); ylabel(ax,'MEP amplitude (mV)');
    title(ax,[channelNames{ch} ' channel'],'FontSize',12,'FontWeight','bold');
  end
  tms_render_export(f,[d.key '.ihi_amplitudes'],r); close(f);
  pageSize=r.ihi_trials_per_page; pages=ceil(d.n/pageSize); rows=ceil(pageSize/2);
  renderedPages=pages; if slim, renderedPages=1; end
  for pg=1:renderedPages
    indices=(pg-1)*pageSize+1:min(pg*pageSize,d.n);
    inches=r.ihi_detail_inches; inches(2)=max(inches(2),rows*3.3);
    f=tms_render_figure(inches,sprintf('IHI | %s | Trials %d-%d | Page %d/%d',d.key,indices(1),indices(end),pg,pages),...
      'New visualization | Blue: right; orange: left (raw) | Dashed: test pulse; dotted: conditioning pulse | Bottom bands: MEP windows; circles: centre / end',r);
    h=.80/rows; panelHeight=.44/rows;
    for k=1:numel(indices)
      tr=indices(k); row=floor((k-1)/2); col=mod(k-1,2);
      ax=tms_render_axes(f,[.085+col*.49 .90-(row+1)*h+.135/rows .385 panelHeight],r);
      for ch=1:2
        hline=plot(ax,t,d.trials(:,ch,tr)*1000,'Color',channelColors(ch,:),'LineWidth',r.line_width,'DisplayName',[channelNames{ch} ' raw EMG']);
        setappdata(hline,'mint_trials',tr);
        drawn=get(hline,'YData'); assert(isequal(drawn(:),d.trials(:,ch,tr)*1000),'Rendered detail trace differs');
      end
      ylim(ax,tms_render_limits(d.trials(:,1:2,tr)*1000)); xlim(ax,[0 t(end)]); set(ax,'XTick',0:100:400,'FontSize',9);
      tms_render_events(ax,d,tr,r,1:2);
      xlabel(ax,'Time (ms)','FontSize',9); ylabel(ax,'Raw EMG (mV)','FontSize',9);
      title(ax,sprintf('Trial %d | %s',tr,strrep(d.classes{tr},'_',' ')),'FontSize',11,'FontWeight','bold');
    end
    tms_render_export(f,sprintf('%s.ihi_trials_p%02d',d.key,pg),r); close(f);
  end
  tms_write_json([d.key '.graphics.json'],struct('id',d.id,'time',d.time,'condition',d.condition,...
    'trials',d.n,'layout','new overview + paginated trials + amplitude summary','left_signal','raw',...
    'onsets',d.onset,'offsets',d.offset,'stim',d.stim,'classes',{d.classes},'amplitudes_mV',d.amp*1000,...
    'class_counts',counts,'finite_amplitude_counts',finiteCounts,'plotted_amplitudes',{plotted},'trials_per_page',pageSize,'pages',renderedPages,...
    'sample_time_ms',[t(1) t(end)],'rate',d.rate,'dpi',r.dpi,'reference','new visualization; no archived IHI figure'));
end
