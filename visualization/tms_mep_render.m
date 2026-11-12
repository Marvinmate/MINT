function tms_mep_render(features,settings,slim)
  if nargin<3, slim=false; end
  r=tms_render_init(settings); x=load(features); d=x.d;
  if slim, r.formats={'png'}; r.export_csv=true; end
  names={'Right EMG','Left EMG'};
  if strcmp(d.protocol,'CSP'), names{1}='Single-channel EMG'; end
  colors=[.05 .32 .62; .78 .26 .12];
  footer='New visualization | Stored amplitudes and events | EMG displayed raw, without filtering';
  if strcmp(d.protocol,'IHI'), footer=[footer ' | Left amplitudes use the historical filtered signal']; end
  f=tms_render_figure(r.mep_inches,['MEP | ' d.key],footer,r);
  ax=tms_render_axes(f,[.09 .61 .86 .27],r);
  for ch=1:2
    if any(isfinite(d.amp(:,ch)))
      h=plot(ax,1:d.n,d.amp(:,ch)*1000,'o-','Color',colors(ch,:),'MarkerSize',4,'MarkerFaceColor','w','LineWidth',.8,'DisplayName',names{ch});
      setappdata(h,'mint_trials',1:d.n);
      drawn=get(h,'YData'); assert(isequaln(drawn(:),d.amp(:,ch)*1000),'Rendered amplitudes differ');
    end
  end
  xlim(ax,[.5 d.n+.5]); xlabel(ax,'Trial'); ylabel(ax,'MEP amplitude (mV)');
  if strcmp(d.protocol,'IHI'), ttl='Individual amplitudes | blue: right; orange: left';
  else, ttl='Individual amplitudes | CSP protocol, single channel'; end
  title(ax,ttl,'FontSize',r.font_size,'FontWeight','bold');
  ax=tms_render_axes(f,[.09 .15 .86 .29],r);
  if strcmp(d.protocol,'CSP')
    raw=d.raw(d.starts(1):d.ends(1)); raw=raw(:); channels=1;
  else, raw=d.trials(:,1:2,1); channels=1:2; end
  t=(0:size(raw,1)-1)*1000/d.rate;
  for ch=channels
    h=plot(ax,t,raw(:,ch)*1000,'Color',colors(ch,:),'LineWidth',r.line_width,'DisplayName',names{ch});
    setappdata(h,'mint_trials',1);
  end
  ylim(ax,tms_render_limits(raw*1000)); xlim(ax,[0 t(end)]); set(ax,'XTick',0:50:400);
  ev=tms_render_events(ax,d,1,r,channels);
  xlabel(ax,'Time within trial (ms; 4000 Hz)'); ylabel(ax,'Raw EMG (mV)');
  title(ax,'Trial 1 | bottom bands: saved MEP windows; circles: centre / end; vertical lines: stimuli','FontSize',10,'FontWeight','bold');
  base=[d.key '.new_mep']; tms_render_export(f,base,r); close(f);
  tms_write_json([base '.graphics.json'],struct('key',d.key,'protocol',d.protocol,'trials',d.n,...
    'amplitudes_mV',d.amp*1000,'onsets',d.onset,'offsets',d.offset,'representative_events',ev,...
    'representative_trial',1,'raw_signal_sha256',tms_sha256(features),'dpi',r.dpi,'inches',r.mep_inches,'reference','new visualization'));
end
