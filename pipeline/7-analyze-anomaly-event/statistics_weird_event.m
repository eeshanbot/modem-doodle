%% prep workspace

clear; clc; close all;

%% load in situ data
[DATA,INDEX] = h_unpack_bellhop('../bellhop-gvel-gridded/gveltable.csv');

%% load post-processing, NBC
listingNew = dir('../bellhop-gvel-gridded/csv_arr/*gridded.csv');
SIM_NEW = h_get_nbc(listingNew,DATA,INDEX);

%% load post-processing, old algorithm
listingOld = dir('../bellhop-gvel-gridded/csv_arr/*old.csv');
SIM_OLD = h_get_mbc(listingOld,DATA);

%% calculate statistics

basevalStat = h_calc_step(SIM_OLD,SIM_NEW,3,INDEX.valid);

eeofStat = h_calc_step(SIM_OLD,SIM_NEW,4,INDEX.valid);

hycomStat = h_calc_step(SIM_OLD,SIM_NEW,5,INDEX.valid);

%% helper function

function [F] = h_calc_step(SIM_OLD,SIM_NEW,fileIndex,indValid)

F.owtt_1 = mean(SIM_OLD{fileIndex}.owtt(indValid));
F.gvel_1 = mean(SIM_OLD{fileIndex}.gvel(indValid));
F.rang_1 = mean(SIM_OLD{fileIndex}.rangeAnomaly(indValid));
F.nbnc_1 = SIM_OLD{fileIndex}.n_bnc(indValid).';

F.owtt_2 = mean(SIM_NEW{fileIndex}.owtt(indValid));
F.gvel_2 = mean(SIM_NEW{fileIndex}.gvel(indValid));
F.rang_2 = mean(SIM_NEW{fileIndex}.rangeAnomaly(indValid));
F.nbnc_2 = SIM_NEW{fileIndex}.numBounces(indValid).';

end