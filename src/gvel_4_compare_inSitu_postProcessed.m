%% gvel_4_compare_inSitu_postProcessed
% compares range anomaly performance between in situ estimation & post
% processing of *NEW* algorithm

clear; clc; close all;

% load modem marker information
load p_modemMarkerDetails

%% load in situ data
global DATA RECAP;
DATA = readtable('./bellhop-gvel-gridded/gveltable.csv');
A = load('./data-prep/tobytest-recap-full.mat'); % loads "event"
RECAP = h_unpack_experiment(A.event);

% remove crazy 11 second event, event that is nominally 1.58* seconds
indBad1 = find(DATA.owtt > 4);
indBad2 = find(strcmp(DATA.rxNode,'East') & DATA.owtt > 1.55);
indBad = union(indBad1,indBad2);

% 1.587 events, had clock errors + Bellhop can't resolve these
DATA.simGvel(indBad) = NaN;

% only simGvel
indValid = ~isnan(DATA.simGvel);

% calculate RangeAnomaly
DATA.rangeAnomaly = DATA.owtt .* DATA.simGvel - DATA.recRange;

%% load post-processing, new algorithm
global SIM;
listing = dir('./bellhop-gvel-gridded/csv_arr/*gridded.csv');

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
        T0.gvel(k) = DATA.recRange(k)./tableDelay(here);
        T0.owtt(k) = tableDelay(here);
        T0.numBounces(k) = here-1;
    end
    
    T0.rangeAnomaly = DATA.owtt .* T0.gvel - DATA.recRange;
    SIM{f} = T0;
end

%% file encoding
% 1 = artifact-baseval
% 2 = artifact-eeof
% 3 = fixed-baseval
% 4 = fixed-eeof
% 5 = hycom

%% figure --- baseval
figure('name','compare-method','renderer','painters','position',[108 108 800 700]);
eof_status = RECAP.eof_bool == 0;
eof_status = eof_status.';
index = boolean(eof_status .* indValid);
h_cross_plot(index);
title('Improvement of range estimation error [m]','fontsize',18);

%% figure helper function
function [] = h_cross_plot(indValid)

global DATA SIM;

% marker shape & color
shapeBounce = {'o','x','s','^','d'};
colorDepth = containers.Map([20 30 90],{[70 240 240]./256,[0 130 200]./256,[0 0 128]./256});

maxVal(1) = max(DATA.rangeAnomaly(indValid));
maxVal(2) = max(SIM{1}.rangeAnomaly(indValid));
maxVal = max(maxVal(:));

% add patch
hold on
p = patch([-maxVal 0 -maxVal maxVal 0 maxVal],[-maxVal 0 maxVal maxVal 0 -maxVal],'w','handlevisibility','off');
p.FaceColor = [0.7 0.7 0.7];
p.FaceAlpha = .3;
p.EdgeColor = 'none';

yline(0,'--','color',[0.7 0.7 0.7 0.7],'linewidth',3,'handlevisibility','off');

hold off

% scatter points
hold on
indHere = find(indValid == 1).';
for k = indHere
    zs = DATA.sourceDepth(k);
    numBounces = SIM{1}.numBounces(k) + 1;
    scatter(DATA.rangeAnomaly(k),SIM{1}.rangeAnomaly(k),...
        150,colorDepth(zs),shapeBounce{numBounces},'linewidth',2,'markeredgealpha',0.6,'handlevisibility','off');
end
hold off

% add grid
grid on

% add text to explain gray box
buff = maxVal/15;
text(-maxVal+buff,maxVal-buff,'more accurate','verticalalignment','top','rotation',-45,'fontsize',11);
text(-maxVal+buff,maxVal-buff,'less accurate than in-situ algorithm','verticalalignment','bottom','rotation',-45,'fontsize',11);

% make xticks and yticks equal
yticks(xticks);

% make plot look nice
axis tight
axis square
xlabel({'in-situ algorithm','\it{minimal bounce criteria}'});
ylabel({'updated algorithm','\it{optimal bounce criteria}'});
set(gca,'fontsize',14);

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
lgdstr = {'20 m','30 m','90 m','','','direct path','1 bounces','2 bounces','3 bounces','4 bounces'};

lg1 = legend(lgdstr,'location','south','NumColumns',2,'fontsize',11);
title(lg1,'   source depth & multipath structure');

end






