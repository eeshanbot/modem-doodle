function [statBack] = h_hist_boxplot(Y,EDGES,COLORS,THRESHOLD)
%h_hist_boxplot makes a beautiful histogram w/ a boxplot underlaid

diffEdges = mean(diff(EDGES))./2;

% histogram
for s = 1:numel(Y)
    h(s,:) = histcounts(Y{s}.count,EDGES,'normalization','probability');
end
B = bar(EDGES(1:end-1)+diffEdges,h,0.9,'FaceColor','flat','EdgeColor','none');

for s = 1:2
    B(s).CData = COLORS{s};
    B(s).FaceAlpha = 0.8;
end

grid on
ylabel('probability');
xticks(EDGES);
xlim([-1 max(EDGES)+1]);

% box plot
hold on
buff = -0.15;


% add bottom "box" plot
hold on
maxY = ceil(max(h(:))*10)/10;
buff = -maxY/5;
ylim([buff maxY]);
yticks([0:0.1:maxY]);

kbuff = buff/3;
for s = 1:2
    
    yval = Y{s}.count;
    
    yval(yval>THRESHOLD) = NaN;
    
    meanVal = mean(yval,'omitnan');
    xQuant1 = quantile(yval,[0 1]);
    xQuant2 = quantile(yval,[.25 .5 .75]);
    
    plot(xQuant1,ones(2,1).*s*kbuff,'handlevisibility','off','color',[COLORS{s} 0.4]);
    plot(xQuant1,s*kbuff,'.','handlevisibility','off','color',COLORS{s},'MarkerSize',15);
    plot(meanVal,s*kbuff,'o','handlevisibility','off','color',COLORS{s},'MarkerSize',12);
    
    plot(xQuant2(1),s*kbuff,'<','handlevisibility','off','color',COLORS{s});
    plot(xQuant2(3),s*kbuff,'>','handlevisibility','off','color',COLORS{s});
    plot(xQuant2(2),s*kbuff,'d','handlevisibility','off','color',COLORS{s});
    
    statBack(s).mean = meanVal;
    statBack(s).minmax = xQuant1;
    statBack(s).percentiles = xQuant2;
    statBack(s).std = std(yval,'omitnan');

end

plot(NaN,NaN,'w');
plot(NaN,NaN,'k.','markersize',15);
plot(NaN,NaN,'k<');
plot(NaN,NaN,'ko','markersize',15);
plot(NaN,NaN,'kd');
plot(NaN,NaN,'k>');

% add legend
legend('Nearest Bounce Criteria','Minimal Bounce Criteria','',...
    'min/max','25th percentile','mean','median','75th percentile',...
    'fontsize',12,'location','NorthEast');


hold off


end

