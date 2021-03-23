%% gvel_4_compare_inSitu_postProcessed
% compares range anomaly performance between in situ estimation & post
% processing

clear; clc; close all;

%% load in situ data
DATA = readtable('./bellhop-gvel-gridded/gveltable.csv');
A = load('./data-prep/tobytest-recap-full.mat'); % loads "event"
RECAP = h_unpack_experiment(A.event);

%% load & filter post-processing
% load simulation
listing = dir('./bellhop-gvel-gridded/csv_arr/*gridded.csv');

for k = 1:numel(listing)
    T0 = readtable([listing(k).folder '/' listing(k).name]);
    T0.index = T0.index + 1;
    b = split(listing(k).name,'.');
    tName{k} = b{1};
    
    % assign gvel for each index by closest time comparison
    for j = 1:numel(T0.index)
        delay = DATA.owtt(j);
        tableDelay = table2array(T0(j,2:6));
        [~,here] = min(abs(tableDelay - delay));
        T0.gvel(j) = DATA.recRange(j)./tableDelay(here);
        T0.owtt(j) = tableDelay(here);
        T0.numBounces(j) = here-1;
    end
    SIM{k} = T0;
end

