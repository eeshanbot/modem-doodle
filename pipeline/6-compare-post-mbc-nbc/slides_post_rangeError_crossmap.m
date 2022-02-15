%% slides_post_rangeError_crossmap.m

% prep workspace
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

figure('name','compare-method-slides-eeof','renderer','painters','position',[108 108 950 900]);

%% figure --- EOF ONLY

% plot
eeof.xVal = SIM_OLD{4}.rangeAnomaly(indValid);
eeof.yVal = SIM_NEW{4}.rangeAnomaly(indValid);
eeof.zs = DATA.sourceDepth(indValid);
eeof.numBounces = SIM_NEW{4}.numBounces(indValid);
eeof.F = h_cross_plot(eeof.xVal,eeof.yVal,eeof.zs,eeof.numBounces);

h_view_plot(eeof.xVal,eeof.yVal,eeof.zs,eeof.numBounces);
%title({sprintf('\\fontsize{16} Post-processed range estimation comparison for all %u beacon to beacon events',sum(indValid)),'\fontsize{13} SSP = Chosen Weights'})

%% legend

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

lg1 = legend(lgdstr,'location','south','NumColumns',2,'fontsize',12);
title(lg1,'   source depth & multipath structure');

%% export

% h_printThesisPNG('SLIDES-compare-weighted-postv1v2');

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

% add text to explain gray box
buff = maxVal/8;
text(-maxVal+buff,maxVal-buff,'minimal bounce is more accurate','verticalalignment','top','rotation',-45,'fontsize',13);
text(-maxVal+buff,maxVal-buff,'nearest bounce is more accurate','verticalalignment','bottom','rotation',-45,'fontsize',13);

% make xticks and yticks equal
axis tight
axis square
xticks(yticks);

% make plot look nice
xlabel({'"in situ" error [m]','\it{minimal bounce criteria}'});
ylabel({'post-processed error [m]','\it{nearest bounce criteria}'});
set(gca,'fontsize',14);


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
xlim([-maxVal maxVal]);
ylim([-maxVal maxVal]);
xtickVal = round(-maxVal,-1):5:round(maxVal,-1);
xticks(xtickVal);
yticks(xtickVal);

axis square

set(gca,'fontsize',14);

end