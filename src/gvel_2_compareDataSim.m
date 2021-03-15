%% gvel_2_checkSim
% makes plots to compare ICEX 20 in situ estimates to post-processing
% simulations

%% prep workspace
clear; clc; close all;

% load data
A = readtable('./bellhop-gvel-gridded/gveltable.csv');
% only simGvel
indValid = ~isnan(A.simGvel);

% load modem marker information
load p_modemMarkerDetails

% load simulated values
listing = dir('./bellhop-gvel/csv_arr/*.csv');

%% tiled layout --- just by owtt

figure('name','check-sim-and-files','renderer','painter','position',[10 10 1100 1000]);
t = tiledlayout('flow','TileSpacing','Compact');

for k = 1:numel(listing)
    T0 = readtable([listing(k).folder '/' listing(k).name]);
    T0.index = T0.index + 1;
    b = split(listing(k).name,'.');
    tName{k} = b{1};
    T0.gvel = A.recRange./T0.owtt;
    T{k} = T0;
    
    
    nexttile
    scatter(A.owtt(indValid),T0.owtt(indValid)-A.owtt(indValid),'filled','MarkerFaceAlpha',0.2);
    grid on
    xlim([0.8 4.2]);
    str = split(listing(k).name,'.');
    title(str(1));
    set(gca,'fontsize',12);
    
    str = sprintf('$$\\delta  \\tilde{t}$$ = %2.4f s ',median(T0.owtt(indValid)-A.owtt(indValid)));
    text(2.5,0.045,str,'VerticalAlignment','top','HorizontalAlignment','right','interpreter','latex','fontsize',14);
    
    ylim([-0.12 0.05])
    xlim([0.9 2.5]);
end

sgtitle('One-way-travel-time errors between in situ prediction & post-processing prediction given various input files');

%% second --- by simgvel

figure('name','check-sim-and-files','renderer','painter','position',[10 10 1100 1000]);
t = tiledlayout('flow','TileSpacing','Compact');

for k = 1:numel(listing)
   
    nexttile
    scatter(A.owtt(indValid),T{k}.gvel(indValid)-A.simGvel(indValid),'filled','MarkerFaceAlpha',0.2);
    grid on
    xlim([0.8 4.2]);
    str = split(listing(k).name,'.');
    title(str(1));
    set(gca,'fontsize',12);
    
    str = sprintf('$$\\delta \\tilde{u}$$ = %2.4f m/s ',median(T{k}.gvel(indValid)-A.simGvel(indValid)));
    text(2.5,15,str,'VerticalAlignment','top','HorizontalAlignment','right','interpreter','latex','fontsize',14);
    
    ylim([-15 15]);
    xlim([0.9 2.5]);
end

sgtitle('Estimated group velocity errors between in situ prediction & post-processing prediction given various input files');
