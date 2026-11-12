function events=tms_render_events(ax,d,tr,r,channels)
  % Display stored event indices; no detector/filter/normalisation is called.
  colors=[.05 .32 .62; .78 .26 .12]; events=struct;
  events.centres=d.onset(tr,:); events.ends=d.offset(tr,:);
  events.starts=nan(1,2); events.stim=d.stim(tr,:);
  yl=ylim(ax);
  names={'Right','Left'};
  if strcmp(d.protocol,'CSP'), names{1}='Single channel'; end
  for ch=channels
    centre=d.onset(tr,ch); stop=d.offset(tr,ch);
    if strcmp(d.protocol,'CSP')
      start=d.windows(tr,1)-d.starts(tr)+1; stop=d.windows(tr,2)-d.starts(tr)+1;
      centre=centre-d.starts(tr)+1;
    else
      % Historical amplitude window is +/- 10 ms around the saved centre.
      start=max(1,centre-round(.010*d.rate));
    end
    events.starts(ch)=start;
    if isfinite(start) && isfinite(stop)
      a=(start-1)*1000/d.rate; b=(stop-1)*1000/d.rate;
      % Separate colour bands at the bottom: no opaque patch covers EMG.
      y=yl(1)+(.025+.045*(ch-1))*diff(yl);
      h=plot(ax,[a b],[y y],'-','Color',colors(ch,:),'LineWidth',4,'DisplayName',[names{ch} ' MEP window']);
      setappdata(h,'mint_trials',tr);
      h=plot(ax,([centre stop]-1)*1000/d.rate,[y y],'o','Color',colors(ch,:),'MarkerSize',3,'MarkerFaceColor','w','DisplayName',[names{ch} ' centre / end']);
      setappdata(h,'mint_trials',tr);
    end
    if isfinite(d.stim(tr,ch))
      x=(d.stim(tr,ch)-1)*1000/d.rate;
      style='--'; if ch==2, style=':'; end
      pulses={'Test pulse','Conditioning pulse'};
      h=plot(ax,[x x],yl,style,'Color',colors(ch,:),'LineWidth',.7,'DisplayName',pulses{ch});
      setappdata(h,'mint_trials',tr);
    end
  end
end
