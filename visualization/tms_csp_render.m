function tms_csp_render(files,science,settings,slim)
  if nargin<4, slim=false; end
  r=tms_render_init(settings); p=tms_init(science); records=tms_load_records(files); id=records{1}.id;
  if slim, r.export_csv=true; end
  order=tms_conditions(records,p); times=sort(unique(cellfun(@(d)d.time,records)));
  detailTimes=times; if slim, detailTimes=times(1); end
  for tp=detailTimes(:)'
    for page=1:ceil(numel(order)/3)
      indices=(page-1)*3+1:min(page*3,numel(order)); count=numel(indices);
      inches=r.csp_inches; inches(2)=max(4,3*count);
      f=tms_render_figure(inches,sprintf('CSP | ID %s | T%d | %s',id,tp,p.csp_end_method),...
        'Raw EMG | Vertical lines: stored peak and selected CSP end | Thin blue segments: MEP measurement windows',r);
      axesData=cell(1,count);
      for panel=1:count
        k=indices(panel); ax=tms_render_axes(f,[.08 .91-panel*.82/count+.10/count .86 .46/count],r);
        subset=records(cellfun(@(d)strcmp(d.condition,order{k}) && d.time==tp,records));
        if isempty(subset)
          plot(ax,NaN,NaN); xlim(ax,[0 1]); ylim(ax,[0 1]); title(ax,[order{k} ' | Missing recording']); continue;
        end
        d=subset{1}; values=d.csp;
        if isfield(d,'csp_method'), assert(strcmp(d.csp_method,p.csp_end_method),'CSP figure method differs from scientific output'); end
        t=(0:numel(d.raw)-1)*1000/d.rate;
        plot(ax,t,d.raw*1000,'Color',[.05 .32 .62],'LineWidth',.65,'DisplayName','Raw EMG');
        lim=tms_render_limits(d.raw*1000); lim(2)=lim(2)+.2*diff(lim); ylim(ax,lim); xlim(ax,[0 t(end)]);
        for tr=1:d.n
          for j=2:3
            event=(values(tr,j)-1)*1000/d.rate;
            if isfinite(event)
              names={'Stored MEP peak','Selected CSP end'};
              marker=plot(ax,[event event],lim,':','Color',[.4 .4 .4],'LineWidth',.6,'DisplayName',names{j-1}); setappdata(marker,'mint_trials',tr);
            end
          end
          y=lim(1)+.04*diff(lim);
          h=plot(ax,(d.windows(tr,:)-1)*1000/d.rate,[y y],'-','Color',[.05 .32 .62],'LineWidth',.7,'DisplayName','MEP measurement window'); setappdata(h,'mint_trials',tr);
          if isfinite(values(tr,3))
            suffix=''; if isfield(d,'included') && ~d.included(tr), suffix=' *'; end
            label=text(ax,(values(tr,3)-1)*1000/d.rate,lim(2)-.035*diff(lim),sprintf('%.1f ms%s',values(tr,1)*1000,suffix),'FontSize',9,'HorizontalAlignment','center','VerticalAlignment','top');
            setappdata(label,'mint_trials',tr); setappdata(label,'mint_value',values(tr,1)*1000);
          end
        end
        title(ax,[order{k} ' | ' num2str(d.n) ' trials (* excluded)'],'FontSize',11,'FontWeight','bold');
        xlabel(ax,'Time within recording (ms)'); ylabel(ax,'Raw EMG (mV)');
        axesData{panel}=struct('condition',d.condition,'durations_ms',values(:,1)*1000,'onsets',values(:,2),'offsets',values(:,3));
      end
      base=sprintf('%s_T%d.modern_csp',id,tp); if page>1, base=sprintf('%s_p%02d',base,page); end
      tms_render_export(f,base,r); close(f);
      tms_write_json([base '.render.json'],struct('figure_method',p.csp_end_method,'axes',{axesData},'dpi',r.dpi,'inches',inches));
    end
  end
  tms_csp_duration_render(records,order,p,r);
end
