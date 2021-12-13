%% gvel_6_compare_inSitu_postProcessed
% compares range anomaly performance between post processing of old and new
% algorithms

clear; clc;

%% load in situ data
DATA = readtable('../pipeline/bellhop-gvel-gridded/gveltable.csv');
A = load('../data/tobytest-recap-clean.mat'); % loads "event"
RECAP = h_unpack_experiment(A.event);

DATA.simGvel(isnan(DATA.simGvel)) = 0;

% remove crazy 11 second event, event that is nominally 1.58* seconds
indBad1 = find(DATA.owtt > 3);
indBad2 = find(strcmp(DATA.rxNode,'East') & DATA.owtt > 1.55);
indBad = union(indBad1,indBad2);

% 1.587 events, had clock errors + Bellhop can't resolve these
DATA.simGvel(indBad) = NaN;
% only simGvel

indValid = 1215:1224;

% calculate RangeAnomaly
DATA.rangeAnomaly = DATA.owtt .* DATA.simGvel - DATA.recRange;

%% load post-processing, new algorithm
listing = dir('../pipeline/bellhop-gvel-gridded/csv_arr/*gridded.csv');

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
listing = dir('../pipeline/bellhop-gvel-gridded/csv_arr/*old.csv');

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

basevalStat = h_calc_step(SIM_OLD,SIM_NEW,3,indValid);

eeofStat = h_calc_step(SIM_OLD,SIM_NEW,4,indValid);

hycomStat = h_calc_step(SIM_OLD,SIM_NEW,5,indValid);

%%

function [F] = h_calc_step(SIM_OLD,SIM_NEW,fileIndex,indValid);

F.owtt_1 = mean(SIM_OLD{fileIndex}.owtt(indValid));
F.gvel_1 = mean(SIM_OLD{fileIndex}.gvel(indValid));
F.rang_1 = mean(SIM_OLD{fileIndex}.rangeAnomaly(indValid));
F.nbnc_1 = SIM_OLD{fileIndex}.n_bnc(indValid).';

F.owtt_2 = mean(SIM_NEW{fileIndex}.owtt(indValid));
F.gvel_2 = mean(SIM_NEW{fileIndex}.gvel(indValid));
F.rang_2 = mean(SIM_NEW{fileIndex}.rangeAnomaly(indValid));
F.nbnc_2 = SIM_NEW{fileIndex}.numBounces(indValid).';

end