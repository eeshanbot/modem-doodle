%% main_plot_ice_drift.m
% plots ice drift from ../data/tobytest-recap-clean.mat

%% prep workspace

clear; clc;

% easily distinguishable colors to link modems
load p_modemMarkerDetails
markerSize = 50;

% legend information
load p_legendDetails

%% load toby test data recap all
load '../data/tobytest-recap-clean.mat'
RECAP = h_unpack_experiment(event);

%% loop

figure(1); clf;

for node = modem_labels
    node = node{1}; % cell array to character
    
    rx_index = find(strcmp(RECAP.tag_rx,node));
    rx_x = RECAP.rx_x(rx_index);
    rx_y = RECAP.rx_y(rx_index);
    rx_t = RECAP.data_time(rx_index);
    rx_z = RECAP.rx_z(rx_index);
    
    tx_index = find(strcmp(RECAP.tag_tx,node));
    tx_x = RECAP.tx_x(tx_index);
    tx_y = RECAP.tx_y(tx_index);
    tx_t = RECAP.data_time(tx_index);
    
    xval = [rx_x tx_x];
    yval = [rx_y tx_y];
    tval = [rx_t tx_t];
    
    [tval,time_index] = sort(tval);
    xval = xval(time_index);
    yval = yval(time_index);
   
    xval = xval - xval(1);
    yval = yval - yval(1);
    rval = sqrt(xval.^2 + yval.^2);    
    
    %% figure: ice drift
    figure(1);
    hold on
    ixlgd = ixlgd + 1;
    Lgd(ixlgd) = scatter(NaN,NaN,markerSize,markerModemMap(node),'o','filled');
    LgdStr{ixlgd} = node;
    scatter(tval, rval,markerSize,markerModemMap(node),'o','filled','MarkerFaceAlpha',.6);
    grid on
    datetick('x');
    ylabel('drift [m]');
    xlabel('time [hr:mm]');
    legend(Lgd,LgdStr,'location','bestoutside');
    
end

%% plot baseval/eeof patch
eof_bool = RECAP.eof_bool;
eof_time = RECAP.data_time;
axis tight
h_plot_patch(eof_bool,eof_time,[.025 .025])
title('Ice Floe Drift from Modem Buoy GPS');
hold off