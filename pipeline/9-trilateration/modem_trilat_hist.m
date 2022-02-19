%% prep workspace

clear; clc; close all;

%% load trilat mat from Oscar
load ../../data/modem_trilat_plus_hists.mat
trilat = trilateration_results;
clear trilateration_results

edges = [0:3:42];
Y{2}.count = trilat.mbc.correction;
Y{1}.count = trilat.nbc.correction;

colors = {[153 51 153]./256,[51 153 153]./256};

%% figure 1 - histogram
figure('name','trilat-histogram','renderer','painters','position',[108 108 1200 500]);

for s = 1:2
    h(s,:) = histcounts(Y{s}.count,edges,'normalization','probability');
end
B = bar(edges(1:end-1)+1.5,h,0.9,'FaceColor','flat','EdgeColor','none');

for s = 1:2
    B(s).CData = colors{s};
    B(s).FaceAlpha = 0.8;
end

grid on
xlabel('Re-navigation RMS error [m]')
ylabel('probability');
xticks(edges);
xlim([-1 39]);
%set(gca,'fontsize',12)
title('Distribution of trilateration corrections')

% add bottom "box" plot
hold on
buff = -0.15;
ylim([buff 0.6]);
yticks([0:0.1:0.6]);

kbuff = .05;
for s = 1:2
    
    yval = Y{s}.count;
    
    yval(yval>40) = NaN;
    
    meanVal = mean(yval,'omitnan');
    xQuant1 = quantile(yval,[0 1]);
    xQuant2 = quantile(yval,[.25 .5 .75]);
    
    plot(xQuant1,ones(2,1).*-s*kbuff,'handlevisibility','off','color',[colors{s} 0.4]);
    plot(xQuant1,-s*kbuff,'.','handlevisibility','off','color',colors{s},'MarkerSize',15);
    plot(meanVal,-s*kbuff,'o','handlevisibility','off','color',colors{s},'MarkerSize',12);
    
    plot(xQuant2(1),-s*kbuff,'<','handlevisibility','off','color',colors{s});
    plot(xQuant2(3),-s*kbuff,'>','handlevisibility','off','color',colors{s});
    plot(xQuant2(2),-s*kbuff,'d','handlevisibility','off','color',colors{s});

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
    'fontsize',12);

hold off

%% export

h_printThesisPNG('trilat-stat');