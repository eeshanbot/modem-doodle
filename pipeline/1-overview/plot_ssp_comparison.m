%% main_plot_ssp_comparison.m
% plots the EOF, baseval, and HYCOM comparison for the gvel calcluations

%% prep workspace
close all; clc; clear all;

%% load ICEX16
load ../../data/icex16Comparison.mat

%% load ICEX20

path = '../bellhop-gvel-gridded/';

file{3} = 'ssp-hycom.csv';
file{2} = 'ssp-fixed-eeof.csv';
file{1} = 'ssp-fixed-baseval.csv';

lineStyleSet = {'-','-','-'};
lineWidthSet = [4 4 4];
colorSet = {[232, 153, 35]./256,[0 85 135]./256,[152 134 117]./256};

%% plot
figure('name','ssp-for-gvel','renderer','painters','position',[108 108 900 1000]);

for k = 1:3
    T = readtable([path file{k}]);
    hold on
    plot(T.Var2,T.Var1,lineStyleSet{k},'color',[colorSet{k} 0.8],'linewidth',lineWidthSet(k));
    hold off
end

hold on
plot(NaN,NaN,'w');
plot(historical.sspVal,historical.sspDepth,':','color',[colorSet{1} 0.8],'linewidth',4);
plot(data.sspVal,data.sspDepth,':','color',[colorSet{2} 0.8],'linewidth',4);
plot(hycom.sspVal,hycom.sspDepth,':','color',[colorSet{3} 0.8],'linewidth',4);
hold off

%% beautify plot
grid on
set(gca,'ydir','reverse');
title('Sound speed estimates');
ylim([0 550])
ytick([0 30 100:100:600]);
yticklabels({'0','30','100','200','300','400','500','600'});
xlim([1431 1462])
ylabel('depth [m]');
xlabel('c [m/s]');

legend('ICEX20: Baseline','ICEX20: Chosen Weights','ICEX20: HYCOM','',...
       'ICEX16: Historical', 'ICEX16: Data','ICEX16: HYCOM',...
       'location','southwest','fontsize',13);
   
%text(1431,20,'20 ','horizontalalignment','right','verticalalignment','middle','fontsize',9);
%text(1431,30,'30 ','horizontalalignment','right','verticalalignment','middle','fontsize',9);
%text(1431,90,'90 ','horizontalalignment','right','verticalalignment','middle','fontsize',9);

   
%% export "isovelocity" assumption

T = readtable([path file{2}]);
ssp = T.Var2;
z = T.Var1;

ind200m = find(z>=200,1,'first');
meanSSP = mean(ssp(1:ind200m));
stdSSP = std(ssp(1:ind200m));

fprintf('Isovelocity SSP = %4.1f +/- %4.1f m/s \n',meanSSP,stdSSP)


%% export
h_printThesisPNG('ssp-gvel-icex20-icex16');