%% main_plot_ice_drift.m
% plots ice drift from ../data/tobytest-recap-clean.mat

%% prep workspace
clear; clc; close all;

lg_font_size = 14;
alpha_color  = .035;

% easily distinguishable colors to link modems
load p_modemMarkerDetails
markerSize = 145;

% legend information
load p_legendDetails

%% load toby test data recap all
load '../data/tobytest-recap-clean.mat'
RECAP = h_unpack_experiment(event);

eof_bool = RECAP.eof_bool;
eof_time = RECAP.data_time;

%% figure 1 : txrx timeline chart

figure('Name','txrx-timeline','Renderer', 'painters', 'Position', [0 0 1280 720]); clf;

% mapping for depth
plotval = -[27 18 9];
plotZMap = containers.Map([90 30 20],plotval);

for rmd = modem_rx_depth
    
    % rx nodes
    index = RECAP.rx_z == rmd;
    rxnodes = RECAP.tag_rx(index);
    uniqueRxNodes = intersect(modem_labels,unique(rxnodes),'stable');
    plotSpread = linspace(0,numel(uniqueRxNodes),numel(uniqueRxNodes));
    plotSpread = plotSpread - mean(plotSpread);
    RX_offsetMap = containers.Map(uniqueRxNodes,plotSpread);
    
    % tx nodes
    index = RECAP.tx_z == rmd;
    txnodes = RECAP.tag_tx(index);
    uniqueTxNodes = intersect(modem_labels,unique(txnodes),'stable');
    plotSpread = linspace(0,numel(uniqueTxNodes),numel(uniqueTxNodes));
    plotSpread = plotSpread - mean(plotSpread);
    TX_offsetMap = containers.Map(uniqueTxNodes,plotSpread);
    
    for node = modem_labels
        node = node{1}; % cell array to character
        
        % RX DEPTHS
        if any(strcmp(uniqueRxNodes,node))
            rx_index = find(strcmp(RECAP.tag_rx,node));
            rx_t = RECAP.data_time(rx_index);
            rx_z = RECAP.rx_z(rx_index);
            
            subplot(2,1,2);
            title('RX depth throughout modem experiment')
            hold on
            
            clear yrx;
            for tNode = 1:numel(rx_z)
                yrx(tNode) = plotZMap(rx_z(tNode)) - RX_offsetMap(node);
            end
            
            unique_rx_z = unique(rx_z);
            
            for rDepth = unique_rx_z
                index = find(rx_z == rDepth);
                scatter(rx_t(index),yrx(index),markerSize,markerModemMap(node),markerShape(rDepth),'filled','MarkerFaceAlpha',0.2);
            end
        end
        
        % TX DEPTHS
        if any(strcmp(uniqueTxNodes,node))
            tx_index = find(strcmp(RECAP.tag_tx,node));
            tx_z = RECAP.tx_z(tx_index);
            tx_t = RECAP.data_time(tx_index);
            
            subplot(2,1,1);
            title('TX depth throughout modem experiment');
            hold on
            
            clear trx;
            for tNode = 1:numel(tx_z)
                trx(tNode) = plotZMap(tx_z(tNode)) - TX_offsetMap(node);
            end
            
            unique_tx_z = unique(tx_z);
            
            for utz = unique_tx_z
                index = find(tx_z == utz);
                scatter(tx_t(index),trx(index),markerSize,markerModemMap(node),markerShape(utz),'filled','MarkerFaceAlpha',0.2);
            end
        end
        
        
    end
end

% common subplot fix
for tNode = 1:2
    subplot(2,1,tNode);
    grid on
    datetick('x');
    axis tight
    ylim([-32 -5])
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
    Lgd(ixlgd) = plot(NaN,NaN,'color',markerModemMap(node{1}),'LineWidth',4);
    LgdStr{ixlgd} = node{1};
end
%legend(Lgd,LgdStr,'location','BestOutside');
legend(Lgd,LgdStr,'Position',[0.9135 0.7945 0.0632 0.1292]);

%% figure 2 : tx rx chart

markerSize = 220;

figure('Name','txrx-chart','Renderer', 'painters', 'Position', [0 0 950 650]); clf;
plot(NaN,NaN,'w');

% txrx chart maps
plotval = [10 20 30];
ZMap = containers.Map([90 30 20],plotval);

% xset up
xTX = 15;
xRX = 19;
xlim([xTX-1 xRX+3])
xticks([xTX xRX])
xticklabels({'tx','rx'})
% y set up

y1 = min(plotval) - 5;
y2 = max(plotval) + 5;
ylim([y1 y2]);
yticks(plotval)
yticklabels([]);
hold on
grid on

patchxval = [xTX-1 xTX+1];
patchyval = ylim();

patchxval = [patchxval(1) patchxval patchxval(end)];
patchyval = [patchyval fliplr(patchyval)];

p = patch(patchxval,patchyval,'k','handlevisibility','off');
p.EdgeColor = 'none';

% add depth label
for txDepth = modem_rx_depth
    text(xTX-1,ZMap(txDepth)-.2,['   z_s = ' num2str(txDepth) ' m'],...
        'color','w','HorizontalAlignment','left','VerticalAlignment','middle','fontsize',12,'fontweight','bold')
end

% mapping for offset
N = 4;
plotspread = linspace(0,N,5) - N/2;
xOffsetMap = containers.Map(modem_labels,plotspread);
x2OffsetMap = containers.Map([20 30 90],[0 0 .3]);
z2OffsetMap = containers.Map([20 30 90],[-.1 -.1  .2]);
textOffsetMap = containers.Map(modem_labels,1.1.*[-1 1 -1 1 -1]);

for txDepth = modem_rx_depth
    
    % tx
    tx_index = find(RECAP.tx_z == txDepth);
    tx_nodes = RECAP.tag_tx(tx_index);
    unique_tx_nodes = intersect(modem_labels,tx_nodes,'stable');
    
    plotspread = linspace(0,numel(unique_tx_nodes),numel(unique_tx_nodes));
    plotspread = plotspread - mean(plotspread);
    zOffsetMap = containers.Map(unique_tx_nodes,plotspread);
    
    for tNode = unique_tx_nodes
        
        scatter(xTX+0.5,ZMap(txDepth) + zOffsetMap(tNode{1}) + z2OffsetMap(txDepth),...
            markerSize,markerModemMap(tNode{1}),markerShape(txDepth),'filled')
        
        tx_node_index = find(strcmp(RECAP.tag_tx,tNode{1}));
        
        rx_nodes = RECAP.tag_rx(tx_node_index);
        rx_z     = RECAP.rx_z(tx_node_index);
        
        unique_rx_nodes = intersect(modem_labels,rx_nodes,'stable');
        unique_rx_z = unique(rx_z);
        
        index1 = strcmp(RECAP.tag_tx,tNode{1});
        index2 = RECAP.tx_z == txDepth;
        
        for rDepth = unique_rx_z
            
            index3 = RECAP.rx_z == rDepth;
            
            for rNode = unique_rx_nodes
                index4 = strcmp(RECAP.tag_rx,rNode{1});
                
                index = index1.*index2.*index3.*index4;
                
                if sum(index)>=1
                    
                    xval = xRX+xOffsetMap(rNode{1})+x2OffsetMap(rDepth);
                    yval = ZMap(txDepth) + zOffsetMap(tNode{1}) + z2OffsetMap(rDepth);

                    scatter(xval,yval,...
                        markerSize,markerModemMap(rNode{1}),markerShape(rDepth),'filled');
                    
                    % add text for amount
                    text(xval,yval - z2OffsetMap(rDepth) + textOffsetMap(tNode{1}),num2str(sum(index)),... 
                        'VerticalAlignment','middle','HorizontalAlignment','center','color',markerModemMap(rNode{1}));
                    
                end
            end
        end
    end
end
% title
title('Successful modem connections');

% make legend
load p_legendDetails.mat

for ml = modem_labels
    index = strcmp(RECAP.tag_rx,ml{1});
    
    depths = RECAP.rx_z(index);
    depths = sort(unique(depths));

    for d = depths
        ixlgd = ixlgd + 1;
        Lgd(ixlgd) = scatter(NaN,NaN,markerSize,markerModemMap(ml{1}),markerShape(d),'filled');
        LgdStr{ixlgd} = [num2str(d) ' m | ' ml{1}];
    end
end
    
legend(Lgd,LgdStr,'location','WestOutside','fontsize',14);