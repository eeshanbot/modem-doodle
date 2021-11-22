%% gvel_2_checkSim
% makes plots to compare ICEX 20 in situ estimates to post-processing
% simulations *of the same algorithm*

%% prep workspace
clear; clc; close all;

% load data
A = readtable('../pipeline/bellhop-gvel-gridded/gveltable.csv');

% remove crazy 11 second event, event that is nominally 1.58* seconds
indBad1 = find(A.owtt > 4);
indBad2 = find(strcmp(A.rxNode,'East') & A.owtt > 1.55);
indBad = union(indBad1,indBad2);

% 1.587 events, had clock errors + Bellhop can't resolve these
A.simGvel(indBad) = NaN;

% only simGvel
indValid = ~isnan(A.simGvel);

% load modem marker information
load p_modemMarkerDetails

% load simulated values
listing = dir('../pipeline/bellhop-gvel/csv_arr/*.csv');

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
    scatter(A.owtt(indValid),T0.owtt(indValid)-A.owtt(indValid),100,'filled','MarkerFaceAlpha',0.1);
    grid on
    xlim([0.8 4.2]);
    str = split(listing(k).name,'.');
    title(str(1));
    set(gca,'fontsize',12);
    
    str = sprintf('$$\\delta  \\tilde{t}$$ = %2.4f s ',median(T0.owtt(indValid)-A.owtt(indValid)));
    text(2.5,0.02,str,'VerticalAlignment','top','HorizontalAlignment','right','interpreter','latex','fontsize',14);
    
    ylim([-0.025 0.025])
    xlim([0.9 2.5]);
end

sgtitle({'One way travel time discrepancies between',...
    'in situ prediction & post-processing algorithm reconstruction given various input files'},'fontweight','bold');

%% second --- by simgvel

figure('name','check-sim-and-files','renderer','painter','position',[10 10 1100 1000]);
t = tiledlayout('flow','TileSpacing','Compact');

for k = 1:numel(listing)
   
    nexttile
    scatter(A.owtt(indValid),T{k}.gvel(indValid)-A.simGvel(indValid),100,'filled','MarkerFaceAlpha',0.1);
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

sgtitle({'Estimated group velocity discrepancies between',...
    'in situ prediction & post-processing algorithm reconstruction given various input files'},'fontweight','bold');