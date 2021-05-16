%% gvel_4_compare_inSitu_postProcessed
% compares range anomaly performance between in situ estimation & post
% processing of *NEW* algorithm

clear; clc; close all;

%% load in situ data
% DATA = readtable('./bellhop-gvel-gridded-simRange/gveltable.csv');

DATA = readtable('./bellhop-gvel-gridded-simRange/gveltable.csv');
indValid1 = ~isnan(DATA.recRange) | ~isnan(DATA.simGvel);
DATA = DATA(indValid1,:);

A = load('../data/tobytest-recap-clean.mat'); % loads "event"
RECAP = h_unpack_experiment(A.event);
indValid2 = ~isnan(RECAP.sim_gvel) | ~isnan(RECAP.sim_range);

EOF_BOOL = double(RECAP.eof_bool(indValid2)).';
GPS_RANGE = RECAP.data_range(indValid2).';
SIM_RANGE = RECAP.sim_range(indValid2).';

%% remove weird event
indBad1 = find(DATA.owtt > 4);
indBad2 = find(strcmp(DATA.rxNode,'East') & DATA.owtt > 1.55);
indBad = union(indBad1,indBad2);

% 1.587 events, had clock errors + Bellhop can't resolve these
DATA.recRange(indBad) = NaN;
DATA.simGvel(indBad) = NaN;

EOF_BOOL(indBad) = NaN;

%% range error for "data" aka ICEX20 implementation
DATA.rangeAnomaly = DATA.owtt .* DATA.simGvel - GPS_RANGE;

%% range error for "sim" aka post processing nearest bounce criterion
listing = dir('./bellhop-gvel-gridded-simRange/csv_arr/*gridded.csv');

for f = 1:numel(listing)
    T0 = readtable([listing(f).folder '/' listing(f).name]);
    T0.index = T0.index + 1;
    b = split(listing(f).name,'.');
    tName{f} = b{1};
    
    % assign gvel for each index by closest time comparison
    for k = 1:numel(T0.index)
        delay = DATA.owtt(k);
        tableDelay = table2array(T0(k,2:6));
        [~,here] = min(abs(tableDelay - delay));
        T0.gvel(k) = SIM_RANGE(k)./tableDelay(here);
        T0.owtt(k) = tableDelay(here);
        T0.numBounces(k) = here-1;
    end
    
    T0.rangeAnomaly = DATA.owtt .* T0.gvel - GPS_RANGE;
    SIM{f} = T0;
end

%% file encoding
% 1 = artifact-baseval
% 2 = artifact-eeof
% 3 = fixed-baseval
% 4 = fixed-eeof
% 5 = hycom

%% figure --- baseval
figure('name','compare-method-baseval','renderer','painters','position',[108 108 950 900]);

% eof status = BASEVAL
index = EOF_BOOL == 0;

% plot
baseval.xVal = DATA.rangeAnomaly(index);
baseval.yVal = SIM{3}.rangeAnomaly(index);
baseval.zs = DATA.sourceDepth(index);
baseval.numBounces = SIM{3}.numBounces(index);
baseval.F = h_cross_plot(baseval.xVal,baseval.yVal,baseval.zs,baseval.numBounces);

% title
bigTitle = '\fontsize{18} Improvement of range estimation error';
smallTitle = sprintf('\\fontsize{14}\\rm SSP = mean of EOF set, N = %u events',sum(index));
title({bigTitle; smallTitle});

h_printThesisPNG('compare-baseval');

%% figure --- EOF
figure('name','compare-method-eeof','renderer','painters','position',[108 108 950 900]);

% eof status = EOF
index = EOF_BOOL == 1;

% plot
eeof.xVal = DATA.rangeAnomaly(index);
eeof.yVal = SIM{4}.rangeAnomaly(index);
eeof.zs = DATA.sourceDepth(index);
eeof.numBounces = SIM{4}.numBounces(index);
eeof.F = h_cross_plot(eeof.xVal,eeof.yVal,eeof.zs,eeof.numBounces);

% title
bigTitle = '\fontsize{18} Improvement of range estimation error';
smallTitle = sprintf('\\fontsize{14}\\rm SSP = chosen weights, N = %u events',sum(index));
title({bigTitle; smallTitle});

h_printThesisPNG('compare-eof');

%% figure --- HYCOM
% figure('name','compare-method-hycom','renderer','painters','position',[108 108 950 900]);
% 
% % load "data" --- redone w/ HYCOM by original algorithm
% dataHYCOM = readtable('./bellhop-gvel/csv_arr/hycom.csv');
% dataHYCOM.rangeAnomaly = DATA.owtt .* (DATA.recRange./dataHYCOM.owtt) - DATA.recRange;
% 
% % plot
% hycom.xVal = dataHYCOM.rangeAnomaly(indValid);
% hycom.yVal = SIM{5}.rangeAnomaly(indValid);
% hycom.zs   = DATA.sourceDepth(indValid);
% hycom.numBounces = SIM{5}.numBounces(indValid);
% hycom.F = h_cross_plot(hycom.xVal,hycom.yVal,hycom.zs,hycom.numBounces);
% 
% % title
% bigTitle = '\fontsize{18} Improvement of range estimation error';
% smallTitle = sprintf('\\fontsize{14}\\rm SSP = HYCOM, N = %u events',sum(indValid));
% title({bigTitle; smallTitle});
% 
% % h_printThesisPNG('compare-hycom');

%% figure helper function
function [F] = h_cross_plot(xVal,yVal,zs,numBounces)

% marker shape & color
shapeBounce = {'o','x','s','^','d'};
colorDepth = containers.Map([20 30 90],{[70 240 240]./256,[0 130 200]./256,[0 0 128]./256});

maxVal(1) = max(xVal);
maxVal(2) = max(yVal);
maxVal = max(maxVal(:));

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
        150,colorDepth(zs(k)),shapeBounce{numBounces(k)+1},'linewidth',2,'markeredgealpha',0.6,'handlevisibility','off');
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

% add text to explain gray box
buff = maxVal/8;
text(-maxVal+buff,maxVal-buff,'more accurate','verticalalignment','top','rotation',-45,'fontsize',11);
text(-maxVal+buff,maxVal-buff,'less accurate than in situ algorithm','verticalalignment','bottom','rotation',-45,'fontsize',11);

% make xticks and yticks equal
axis tight
axis square
xticks(yticks);

% make plot look nice
xlabel({'in situ algorithm error [m]','\it{minimal bounce criteria}'});
ylabel({'updated algorithm error [m]','\it{nearest bounce criteria}'});
set(gca,'fontsize',14);

% add legend
hold on
for s = [20 30 90]
    plot(NaN,NaN,'color',colorDepth(s),'linewidth',6);
end

plot(NaN,NaN,'w');

for r = 1:5
    plot(NaN,NaN,shapeBounce{r},'color','k')
end
hold off
lgdstr = {' 20 m',' 30 m',' 90 m','','direct path','1 bounce','2 bounces','3 bounces'};

lg1 = legend(lgdstr,'location','south','NumColumns',2,'fontsize',11);
title(lg1,'   source depth & multipath structure');

end