%% gvel_5_compare_inSitu_postProcessed
% compares range anomaly performance between post processing of old and new
% algorithms

clear; clc;

%% load in situ data
DATA = readtable('./bellhop-gvel-gridded/gveltable.csv');
A = load('./data-prep/tobytest-recap-full.mat'); % loads "event"
RECAP = h_unpack_experiment(A.event);

DATA.simGvel(isnan(DATA.simGvel)) = 0;

% remove crazy 11 second event, event that is nominally 1.58* seconds
indBad1 = find(DATA.owtt > 3);
indBad2 = find(strcmp(DATA.rxNode,'East') & DATA.owtt > 1.55);
indBad = union(indBad1,indBad2);

% 1.587 events, had clock errors + Bellhop can't resolve these
DATA.simGvel(indBad) = NaN;
% only simGvel

indValid = ~isnan(DATA.simGvel);

% calculate RangeAnomaly
DATA.rangeAnomaly = DATA.owtt .* DATA.simGvel - DATA.recRange;

% of interest
roi = 1215:1224;

%% load post-processing, new algorithm
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
    SIM_NEW{f} = T0;
end

%% load post-processing, old algorithm
listing = dir('./bellhop-gvel-gridded/csv_arr/*old.csv');

for f = 1:numel(listing)
    T0 = readtable([listing(f).folder '/' listing(f).name]);
    T0.index = T0.index + 1;
    b = split(listing(f).name,'.');
    tName{f} = b{1};
    
    % assign gvel by minimum bounce
    for k = 1:numel(T0.index)
        T0.gvel(k) = DATA.recRange(k)./T0.owtt(k);
    end
    
    T0.rangeAnomaly = DATA.owtt .* T0.gvel - DATA.recRange;
    SIM_OLD{f} = T0;
end

%% file encoding
% 1 = artifact-baseval
% 2 = artifact-eeof
% 3 = fixed-baseval
% 4 = fixed-eeof
% 5 = hycom

%% figure --- baseval
%figure('name','compare-method-baseval','renderer','painters','position',[108 108 1000 900]);

index = indValid;

% plot
baseval.xVal = SIM_OLD{3}.rangeAnomaly(index);
baseval.yVal = SIM_NEW{3}.rangeAnomaly(index);
baseval.zs = DATA.sourceDepth(index);
baseval.numBounces = SIM_NEW{3}.numBounces(index);
baseval.F = h_cross_plot(baseval.xVal,baseval.yVal,baseval.zs,baseval.numBounces);

%% figure --- EOF
%figure('name','compare-method-eeof','renderer','painters','position',[108 108 1000 900]);

% only simGvel
index = indValid;

% plot
eeof.xVal = SIM_OLD{4}.rangeAnomaly(indValid);
eeof.yVal = SIM_NEW{4}.rangeAnomaly(index);
eeof.zs = DATA.sourceDepth(index);
eeof.numBounces = SIM_NEW{4}.numBounces(index);
eeof.F = h_cross_plot(eeof.xVal,eeof.yVal,eeof.zs,eeof.numBounces);

%% figure --- HYCOM
%figure('name','compare-method-hycom','renderer','painters','position',[108 108 1000 900])

% plot
hycom.xVal = SIM_OLD{5}.rangeAnomaly(indValid);
hycom.yVal = SIM_NEW{5}.rangeAnomaly(indValid);
hycom.zs   = DATA.sourceDepth(indValid);
hycom.numBounces = SIM_NEW{5}.numBounces(indValid);
hycom.F = h_cross_plot(hycom.xVal,hycom.yVal,hycom.zs,hycom.numBounces);

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