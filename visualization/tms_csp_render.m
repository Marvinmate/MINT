function tms_csp_render(files,science,settings,slim)
  if nargin<4, slim=false; end
  % Current figures only; historical exports are preserved under tests/reference.
  r=tms_render_init(settings); p=jsondecode(fileread(science)); records=tms_load_records(files); id=records{1}.id;
  if slim, r.formats={'png'}; r.export_csv=true; end
  order={'Full','Half','Pbo'}; version=p.default_figure_version;
  if isfield(p.csp_figure_versions,['p' id]), version=p.csp_figure_versions.(['p' id]); end
  times=sort(unique(cellfun(@(d)d.time,records)));
  for tp=times(:)'
    f=tms_render_figure(r.csp_inches,sprintf('CSP | ID %s | T%d | Reference markers %s',id,tp,version),...
      'New presentation | Raw signal and stored historical markers | Numeric exports remain v2 | Durations shown above each saved offset',r);
    axesData=cell(1,3);
    for k=1:3
      ax=tms_render_axes(f,[.08 .73-(k-1)*.29 .86 .16],r);
      subset=records(cellfun(@(d)strcmp(d.condition,order{k}) && d.time==tp,records));
      if isempty(subset), title(ax,[order{k} ' | Missing recording']); continue; end
      d=subset{1}; values=d.csp; if strcmp(version,'v1'), values=d.v1; end
      t=(0:numel(d.raw)-1)*1000/d.rate;
      plot(ax,t,d.raw*1000,'Color',[.05 .32 .62],'LineWidth',.65,'DisplayName','Raw EMG');
      lim=tms_render_limits(d.raw*1000); lim(2)=lim(2)+.2*diff(lim); ylim(ax,lim); xlim(ax,[0 t(end)]);
      for tr=1:d.n
        for j=2:3
          x=(values(tr,j)-1)*1000/d.rate;
          if isfinite(x)
            markers={'Saved onset','Saved offset'};
            marker=plot(ax,[x x],lim,':','Color',[.4 .4 .4],'LineWidth',.6,'DisplayName',markers{j-1});
            setappdata(marker,'mint_trials',tr);
          end
        end
        if isfinite(values(tr,3))
          label=text(ax,(values(tr,3)-1)*1000/d.rate,lim(2)-.035*diff(lim),sprintf('%.1f ms',values(tr,1)*1000),...
            'FontSize',9,'HorizontalAlignment','center','VerticalAlignment','top');
          setappdata(label,'mint_trials',tr);
          setappdata(label,'mint_value',values(tr,1)*1000);
        end
      end
      title(ax,[order{k} ' | ' num2str(d.n) ' trials'],'FontSize',11,'FontWeight','bold');
      xlabel(ax,'Time within recording (ms)'); ylabel(ax,'Raw EMG (mV)');
      axesData{k}=struct('condition',d.condition,'durations_ms',values(:,1)*1000,'onsets',values(:,2),'offsets',values(:,3));
    end
    base=sprintf('%s_T%d.modern_csp',id,tp); tms_render_export(f,base,r); close(f);
    tms_write_json([base '.render.json'],struct('reference','new presentation; historical references archived','figure_version',version,'axes',{axesData},'dpi',r.dpi,'inches',r.csp_inches));
  end
end
