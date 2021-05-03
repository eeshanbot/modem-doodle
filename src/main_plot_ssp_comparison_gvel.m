%% main_plot_ssp_comparison.m
% plots the EOF, baseval, and HYCOM comparison for the gvel calcluations

close all; clc; clear all;

path = './bellhop-gvel-gridded/';

file{3} = 'ssp-hycom.csv';
file{2} = 'ssp-fixed-eeof.csv';
file{1} = 'ssp-fixed-baseval.csv';

lineStyleSet = {'-','-','-'};
lineWidthSet = [4 3 4];
colorSet = {[232, 153, 35]./256,[0 85 135]./256,[152 134 117]./256};

figure('name','ssp-for-gvel','renderer','painters','position',[108 108 400 800]);

for k = 1:3
    T = readtable([path file{k}]);
    hold on
    plot(T.Var2,T.Var1,lineStyleSet{k},'color',[colorSet{k} 0.8],'linewidth',lineWidthSet(k));
    hold off
end

% beautify plot
grid on
set(gca,'ydir','reverse');
title('Sound speed estimates');
ylim([0 500])
xlim([1431 1461])
ylabel('depth [m]');
xlabel('c [m/s]');

legend('Mean of EOF set','Chosen EOF weights','HYCOM','location','southwest','fontsize',13);

h_printThesisPNG('ssp-gvel');
