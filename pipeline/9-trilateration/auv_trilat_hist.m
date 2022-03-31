%% prep workspace

clear; clc; close all;

%% load trilat mat from Oscar
load ../../data/auv_ops_trilat_plus_hists.mat
trilat = trilateration_results;
clear trilateration_results

colors = {[153 51 153]./256,[51 153 153]./256};

Y{2}.error = trilat.mbc.error;
Y{1}.error = trilat.nbc.error;

N = numel(Y{1}.error);


%% figure
figure('name','trilat-histogram','renderer','painters','position',[108 108 1200 1000]);
t = tiledlayout(2,1,'TileSpacing','compact','Padding','Compact');

%% tile 1 - histogram of corrections
nexttile(1);

edges = [0:5:65];
Y{2}.count = trilat.mbc.correction;
Y{1}.count = trilat.nbc.correction;
h_hist_boxplot(Y,edges,colors,max(edges));

xlabel('correction [m rms]')
set(gca,'fontsize',13)
title(sprintf('Distribution of AUV re-navigation corrections (n=%u)',N),'fontsize',15)

legend off

%% tile 2 - histogram of error
nexttile(2);

edges = [0:3:21];
Y{1}.count = trilat.nbc.error;
Y{2}.count = trilat.mbc.error;

h_hist_boxplot(Y,edges,colors,max(edges));
xlabel('error [m rms]')
set(gca,'fontsize',13)
title({'',...
    sprintf('Distribution of AUV re-navigation error (n=%u)',N)}...
    ,'fontsize',15)

%% export

h_printThesisPNG('auv-trilat-stat');