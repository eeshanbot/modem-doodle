%% main_plot_ice_drift.m
% plots ice drift from ../data/tobytest-recap-clean.mat

%% prep workspace

clear; clc;

lg_font_size = 14;
markerSize = 75;
alpha_grey      = [0.6 0.6 0.6];
alpha_color     = .035;

% tetradic colors to link modem colors
modem_colors = {[177 0 204]./256,[7 201 0]./256,[0 114 201]./256,[255 123 0]./256,[40 40 40]./256};
modem_labels = {'North','South','East','West','Camp'};
markerModemMap = containers.Map(modem_labels,modem_colors);

% legend information
ixlgd1 = 0;
Lgd1 = [];
LgdStr1 = {};

ixlgd2 = 0;
Lgd2 = [];
LgdStr2 = {};

% modem depths
rx_depth = [20 30 90];
markerShape(20) = 's';
markerShape(30) = '^';
markerShape(90) = 'v';

%% load toby test data recap all
load '../data/tobytest-recap-clean.mat'
RECAP = h_unpack_experiment(event);

%% loop

figure(1); clf;

figure(2); clf;

for node = modem_labels
    node = node{1}; % cell array to character
        
    rx_index = find(strcmp(RECAP.tag_rx,node));
    rx_x = RECAP.rx_x(rx_index);
    rx_y = RECAP.rx_y(rx_index);
    rx_t = RECAP.data_time(rx_index);
    rx_z = RECAP.rx_z(rx_index);
        
%         tx_index = find(strcmp(RECAP.tag_tx,node));
%         tx_x = RECAP.tx_x(tx_index);
%         tx_y = RECAP.tx_y(tx_index);
%         tx_t = RECAP.data_time(tx_index);
%     
%         xval = [rx_x tx_x];
%         yval = [rx_y tx_y];
%         tval = [rx_t tx_t];
    
    xval = rx_x - rx_x(1);
    yval = rx_y - rx_y(1);
    rval = sqrt(xval.^2 + yval.^2);
    tval = rx_t;
    
    [tval,time_index] = sort(tval);
    xval = xval(time_index);
    yval = yval(time_index);
    
    %% figure: ice drift
    figure(1);
    hold on
    ixlgd1 = ixlgd1 + 1;
    Lgd1(ixlgd1) = scatter(tval, rval,markerSize,markerModemMap(node),'s','filled','MarkerFaceAlpha',0.3);
    LgdStr1{ixlgd1} = node;
    grid on
    datetick('x');
    ylabel('drift [m]');
    axis tight
    xlabel('time [hr:mm]');
    legend(Lgd1,LgdStr1,'location','bestoutside');

    %% figure : rx/tx depth
    figure(2);
    
    % mapping for depth
    plotval = -[30 20 10];
    plotZMap = containers.Map([90 30 20],plotval);
    
    % mapping for offset
    N = 4;
    plotspread = linspace(0,N,5) - N/2;
    offsetMap = containers.Map(modem_labels,plotspread);
    
    % rx depths
    subplot(2,1,2);
    hold on
    
    clear yrx trx;
    for k = 1:numel(rx_z)
        yrx(k) = plotZMap(rx_z(k)) + offsetMap(node);
    end
    
    scatter(tval,yrx,markerSize,markerModemMap(node),'s','filled','MarkerFaceAlpha',0.5);
    grid on
    datetick('x');
    ylabel('depth [m]');
    axis tight
    ylim([-35 -5])
    yticks(plotval);
    yticklabels({'90','30','20'});
    xlabel('time [hr:mm]');
    
    % tx depths
    subplot(2,1,1);
    hold on
    
    tx_index = find(strcmp(RECAP.tag_tx,node));
    tx_z = RECAP.tx_z(tx_index);
    tval = RECAP.data_time(tx_index);
    
    for k = 1:numel(tx_z)
        trx(k) = plotZMap(tx_z(k)) + offsetMap(node);
    end
    
    ixlgd2 = ixlgd2 + 1;
    Lgd2(ixlgd2) = scatter(tval,trx,markerSize,markerModemMap(node),'s','filled','MarkerFaceAlpha',0.5);
    LgdStr2{ixlgd2} = node;
    legend(Lgd2,LgdStr2,'location','BestOutside');
    grid on
    datetick('x');
    ylabel('depth [m]');
    axis tight
    ylim([-35 -5])
    yticks(plotval);
    yticklabels({'90','30','20'});
    
        
end

%% plot baseval/eeof patch

eof_bool = RECAP.eof_bool;
eof_time = RECAP.data_time;
tx_z = RECAP.tx_z;
rx_z = RECAP.rx_z;

% figure 1
figure(1);
plot_patch(eof_bool,eof_time)
title('Ice Floe Drift from Modem Buoy GPS');
hold off

% figure 2
figure(2);

subplot(2,1,1);
title('TX depth throughout experiment');
plot_patch(eof_bool,eof_time);
hold off

subplot(2,1,2)
title('RX depth throughout experiment');
plot_patch(eof_bool,eof_time);
hold off


%% helper function : plot_patch
function [] = plot_patch(eof_bool,eof_time)

% get ybounds
ybounds = ylim();

% figure out how many patches we neek
kindex = find(diff(eof_bool)~=0);

bool_open = eof_bool(1);
bool_close = eof_bool(end);

if bool_open
    kindex = [1 kindex];
end

if bool_close
    kindex = [kindex numel(eof_time)];
end

% loop through patches -- eeof ON
for k = 1:numel(kindex)/2
    
    patchTime = [eof_time(kindex(2*k-1)) eof_time(kindex(2*k))];
    
    buffer = 4;
    
    patchTime = [patchTime(1) patchTime patchTime(end)];
    patchVal = ybounds(2).*ones(size(patchTime));
    patchVal(1) = ybounds(1)-1;
    patchVal(end) = ybounds(1)-1;
    p = patch(patchTime,patchVal,'w','handlevisibility','off');
    p.FaceColor = [0.7 0.7 0.7];
    p.EdgeColor = 'none';
    p.FaceAlpha = .137;
    
    text(patchTime(1),max(patchVal),' eeof',...
       'HorizontalAlignment','left','fontsize',13,'fontangle','italic','VerticalAlignment','top')
end

% loop through blanks -- eeof OFF
for k = 1:numel(kindex)/2 - 1
    patchTime = [eof_time(kindex(2*k):kindex(2*k+1))];
    
   text(patchTime(1),max(patchVal),' baseval',...
       'HorizontalAlignment','left','fontsize',13,'fontangle','italic','VerticalAlignment','top')


end
        
end