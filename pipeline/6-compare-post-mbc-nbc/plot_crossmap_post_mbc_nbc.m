%% prep workspace
clear; clc; close all;

%% load in situ data
[DATA,INDEX] = h_unpack_bellhop('../bellhop-gvel-gridded/gveltable.csv');
indValid = INDEX.valid;

%% calculate minimal bounce critera
listingOld = dir('../bellhop-gvel-gridded/csv_arr/*old.csv');
SIM_OLD = h_get_mbc(listingOld,DATA);

%% calculate nearest bounce criteria
listingNew = dir('../bellhop-gvel-gridded/csv_arr/*gridded.csv');
SIM_NEW = h_get_nbc(listingNew,DATA,INDEX);

%% plot things

global shapeBounce colorDepth;

% marker shape & color
shapeBounce = {'o','x','s','^','d'};
colorDepth = containers.Map([20 30 90],{[70 240 240]./256,[0 130 200]./256,[0 0 128]./256});

figure('name','compare-method-postv1-postv2','renderer','painters','position',[108 108 1470 490]);
t = tiledlayout(1,3,'Padding','compact','TileSpacing','Compact');

%% figure --- baseval

% plot
baseval.xVal = SIM_OLD{3}.rangeAnomaly(indValid);
baseval.yVal = SIM_NEW{3}.rangeAnomaly(indValid);
baseval.zs = DATA.sourceDepth(indValid);
baseval.numBounces = SIM_NEW{3}.numBounces(indValid);
baseval.F = h_cross_plot(baseval.xVal,baseval.yVal,baseval.zs,baseval.numBounces);

nexttile;
h_view_plot(baseval.xVal,baseval.yVal,baseval.zs,baseval.numBounces);
title('SSP = Baseline','fontsize',13);
xlabel({'minimal bounce criterion error [m]'});
ylabel({'nearest bounce criterion error [m]'});

%% figure --- EOF

% plot
eeof.xVal = SIM_OLD{4}.rangeAnomaly(indValid);
eeof.yVal = SIM_NEW{4}.rangeAnomaly(indValid);
eeof.zs = DATA.sourceDepth(indValid);
eeof.numBounces = SIM_NEW{4}.numBounces(indValid);
eeof.F = h_cross_plot(eeof.xVal,eeof.yVal,eeof.zs,eeof.numBounces);

nexttile;
h_view_plot(eeof.xVal,eeof.yVal,eeof.zs,eeof.numBounces);
title({sprintf('\\fontsize{16} Pseudorange error comparison for all %u beacon to beacon events',sum(indValid)),'\fontsize{13} SSP = Chosen Weights'})
yticklabels([]);
xlabel({'minimal bounce criterion error [m]'});

%% figure --- HYCOM

% plot
hycom.xVal = SIM_OLD{5}.rangeAnomaly(indValid);
hycom.yVal = SIM_NEW{5}.rangeAnomaly(indValid);
hycom.zs   = DATA.sourceDepth(indValid);
hycom.numBounces = SIM_NEW{5}.numBounces(indValid);
hycom.F = h_cross_plot(hycom.xVal,hycom.yVal,hycom.zs,hycom.numBounces);

nexttile;
h_view_plot(hycom.xVal,hycom.yVal,hycom.zs,hycom.numBounces);
title('SSP = HYCOM','fontsize',13);
yticklabels([]);
xlabel({'minimal bounce criterion error [m]'});

%% legend
nexttile(2);

% add legend
hold on
for s = [20 30 90]
    plot(NaN,NaN,'color',colorDepth(s),'linewidth',6);
end

plot(NaN,NaN,'w');
plot(NaN,NaN,'w');

for r = 1:5
    plot(NaN,NaN,shapeBounce{r},'color','k')
end
hold off
lgdstr = {' 20 m',' 30 m',' 90 m','','','direct path','1 bounce','2 bounces','3 bounces','4 bounces'};

lg1 = legend(lgdstr,'location','south','NumColumns',2,'fontsize',10);
title(lg1,'   source depth & multipath structure');

%% export

h_printThesisPNG('compare-methods-postv1v2');

%% figure helper function
function [F] = h_cross_plot(xVal,yVal,zs,numBounces)

xVal = abs(xVal);
yVal = abs(yVal);

F.Xquant = quantile(xVal,[0 0.25 0.5 0.75 1]);
F.Xmean = mean(xVal);
F.Xstd = std(xVal);

F.Yquant = quantile(yVal,[0 0.25 0.5 0.75 1]);
F.Ymean = mean(yVal);
F.Ystd = std(yVal);

end

%% figure helper function
function [F] = h_view_plot(xVal,yVal,zs,numBounces)

global shapeBounce colorDepth;

% marker shape & color
shapeBounce = {'o','x','s','^','d'};
colorDepth = containers.Map([20 30 90],{[70 240 240]./256,[0 130 200]./256,[0 0 128]./256});

maxVal(1) = max(xVal);
maxVal(2) = max(yVal);
maxVal = max(maxVal(:));
maxVal = 24;

% add patch
hold on
p = patch([-maxVal 0 -maxVal maxVal 0 maxVal],[-maxVal 0 maxVal maxVal 0 -maxVal],'w','handlevisibility','off');
p.FaceColor = [0.7 0.7 0.7];
p.FaceAlpha = .3;
p.EdgeColor = 'none';
hold off

% scatter points
hold on
for k = 1:numel(zs)
    scatter(xVal(k),yVal(k),...
        150,colorDepth(zs(k)),shapeBounce{numBounces(k)+1},'linewidth',2,'markeredgealpha',0.3,'handlevisibility','off');
end
hold off

% performance metrics
F.dataMean = mean(abs(xVal));
F.simMean = mean(abs(yVal));
F.dataMedian = median(abs(xVal));
F.simMedian = median(abs(yVal));
F.dataStd = std(abs(xVal));
F.simStd = std(abs(yVal));
F.eff = sum(abs(yVal) <= abs(xVal))./numel(xVal);

% add grid
grid on

% make xticks and yticks equal
xlim([-21 21]);
ylim([-21 21]);
xtickVal = -20:5:20;
xticks(xtickVal);
yticks(xtickVal);

axis square

set(gca,'fontsize',12);

end