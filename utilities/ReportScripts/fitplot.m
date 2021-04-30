function fitplot_v2( SimDataI, data )

ColOrd = get(gca,'ColorOrder'); %close;
[m,n] = size(ColOrd);

ngrp=length(SimDataI);

for k = 1:ngrp
    
    % plot data
    xdata=data(k).Time;
    ydata=data(k).Data(:,strcmp('Conc',data(k).DataNames)==1);
    ColRow=rem(k,m)+1;
    Col=ColOrd(ColRow,:);
    semilogy(xdata,ydata,'o','Color',Col,'LineWidth',2);
    hold on
    
    % plot simulation
    xsim=SimDataI(k).Time;
    ysim=SimDataI(k).Data(:,strcmp('central Ab (ug/ml)',SimDataI(k).DataNames)==1);
    semilogy(xsim,ysim,'-','Color',Col,'LineWidth',2);
    hold on

end

set(gca,'FontSize',14)
xlabel('Time','FontSize',14)
ylabel('Concentration','FontSize',14)

end


