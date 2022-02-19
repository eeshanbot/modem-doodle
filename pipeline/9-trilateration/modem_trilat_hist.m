%% prep workspace

clear; clc; close all;

%% load trilat mat from Oscar
load ../../data/modem_trilat_plus_hists.mat
trilat = trilateration_results;
clear trilateration_results

edges = [0:3:48];
Y{2}.count = trilat.mbc.correction;
Y{1}.count = trilat.nbc.correction;
N = numel(Y{1}.count);

colors = {[153 51 153]./256,[51 153 153]./256};

%% figure
figure('name','trilat-histogram','renderer','painters','position',[108 108 1200 500]);

h_hist_boxplot(Y,edges,colors,48);

%% dress up figure
xlabel('RMS of position correction [m]')
set(gca,'fontsize',13)
title(sprintf('Distribution of beacon re-positioning corrections (n=%u)',N),'fontsize',15);

%% export
h_printThesisPNG('beacon-trilat-stat');