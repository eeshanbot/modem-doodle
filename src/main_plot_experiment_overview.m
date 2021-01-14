%% main_plot_ice_drift.m
% plots ice drift from ../data/tobytest-recap-clean.mat

%% prep workspace

clear; clc;

lg_font_size = 14;
alpha_color  = .035;

% easily distinguishable colors to link modems
load p_modemMarkerDetails
markerSize = 150;

% legend information
load p_legendDetails

%% load toby test data recap all
load '../data/tobytest-recap-clean.mat'
RECAP = h_unpack_experiment(event);

eof_bool = RECAP.eof_bool;
eof_time = RECAP.data_time;

%% figure 1 : rx/tx timeline chart

figure(1); clf;

% mapping for depth
plotval = -[30 20 10];
plotZMap = containers.Map([90 30 20],plotval);

for rmd = modem_rx_depth
    
    index = find(RECAP.rx_z == rmd);
    nodes = RECAP.tag_rx(index);
    
    uniqueNodes = unique(nodes);
    numUniqueNodes = numel(uniqueNodes);
    
    plotSpread = linspace(-2,2,numUniqueNodes);
    plotSpread = plotSpread - mean(plotSpread);
    offsetMap = containers.Map(uniqueNodes,plotSpread);
    
    for node = modem_labels
        node = node{1}; % cell array to character
        
        if any(strcmp(uniqueNodes,node))
            % rx depths
            rx_index = find(strcmp(RECAP.tag_rx,node));
            rx_t = RECAP.data_time(rx_index);
            rx_z = RECAP.rx_z(rx_index);
            
            subplot(2,1,2);
            title('RX depth throughout modem experiment')
            hold on
            
            clear yrx;
            for k = 1:numel(rx_z)
                yrx(k) = plotZMap(rx_z(k)) + offsetMap(node);
            end
            
            scatter(rx_t,yrx,markerSize,markerModemMap(node),'s','filled','MarkerFaceAlpha',0.5);
            
            % tx depths
            tx_index = find(strcmp(RECAP.tag_tx,node));
            tx_z = RECAP.tx_z(tx_index);
            tx_t = RECAP.data_time(tx_index);
            
            subplot(2,1,1);
            title('TX depth throughout modem experiment');
            hold on
            
            clear trx;
            for k = 1:numel(tx_z)
                trx(k) = plotZMap(tx_z(k)) + offsetMap(node);
            end
            
            scatter(tx_t,trx,markerSize,markerModemMap(node),'s','filled','MarkerFaceAlpha',0.5);
        end
    end
end

% common subplot fix
for k = 1:2
    subplot(2,1,k);
    grid on
    datetick('x');
    axis tight
    ylim([-35 -7])
    h_plot_patch(eof_bool,eof_time,[.025 .015]);
    ylabel('depth [m]');
    yticks(plotval);
    yticklabels({'90','30','20'});
end

xlabel('time [hr:mm]');

% legend
subplot(2,1,1);
hold on
for node = modem_labels
    ixlgd = ixlgd + 1;
    Lgd(ixlgd) = scatter(NaN,NaN,markerSize,markerModemMap(node{1}),'s','filled');
    LgdStr{ixlgd} = node{1};
end
legend(Lgd,LgdStr,'location','BestOutside');


%     %% figure 3 --- tx rx chart
%
%     figure(3); hold on
%
%     % txrx chart maps
%     plotval = [10 20 30 40 50];
%     txrxZMap = containers.Map(modem_labels, plotval);
%     % mapping for offset
%     N = 3;
%     plotspread = linspace(0,N,3) - N/2;
%     txrxOffsetMap = containers.Map([20 30 90],plotspread);
%
%     % tx values
%     unique_tx_z = unique(tx_z);
%     for utz = unique_tx_z
%         scatter(0, txrxZMap(node),...
%             markerSize,markerModemMap(node),markerShape(utz),'filled');
%     end
%
%     %rx connections
%     rx_node = RECAP.tag_rx(tx_index);
%     rx_z    = RECAP.rx_z(tx_index);
%
%     for r = 1:numel(rx_node)
%         scatter(1+offsetMap(rx_node{r})/10,txrxZMap(node)+txrxOffsetMap(rx_z(r)),...
%             markerSize,markerModemMap(rx_node{r}),markerShape(rx_z(r)),'filled');
%     end
%
%
%     yticks(plotval);
%     yticklabels([]);
%     ylim([plotval(1)-10 plotval(end)+10]);
%     xticks([0 1]);
%     xticklabels({'tx','rx'})
%     xlim([-0.1 1.5]);
%
% end

%% plot baseval/eeof patch


% tx_z = RECAP.tx_z;
% rx_z = RECAP.rx_z;
%
% % figure 1
% figure(1);
% h_plot_patch(eof_bool,eof_time)
% title('Ice Floe Drift from Modem Buoy GPS');
% hold off
%
% % figure 2
% figure(2);
%
% subplot(2,1,1);
% title('TX depth throughout experiment');
% h_plot_patch(eof_bool,eof_time);
% hold off
%
% subplot(2,1,2)
% title('RX depth throughout experiment');
% h_plot_patch(eof_bool,eof_time);
% hold off
%
% % figure 3
% figure(3)
% title('modem connections')



