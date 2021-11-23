%% main_plot_ttrecap_tx.m
% eeshan bhatt

%% prep workspace
clear; clc; close all

lg_font_size = 14;

charcoalGray = [0.6 0.6 0.6];
alphaColor   = .035;

% depth_switch = [20 30 90];
zs = 90;

% load modem marker information
load p_modemMarkerDetails

%% load bathymetry data
bathyfile = '../data/etopo1_bedrock.nc';
plotBathy = h_unpack_bathy(bathyfile);

%% load toby test data by experiment design
A = load('../data/tobytest-recap-clean.mat'); % loads "event"
RECAP = h_unpack_experiment(A.event);

%% figure : timeline

figure('Name','timeline','Renderer', 'painters', 'Position', [10 10 1700 1100]); clf;
load p_legendDetails.mat

for node = RECAP.unique_rx
    node = node{1};
    for imd = modem_rx_depth
        index1 = find(strcmp(RECAP.tag_rx,node) & RECAP.rx_z == imd);
        
        if sum(index1) > 0
            % group velocity estimates (simulation)
            subplot(3,1,3);
            hold on
            scatter(RECAP.sim_time(index1),RECAP.sim_gvel(index1),...
                markerSize,markerModemMap(node),markerShape(imd),'filled','MarkerFaceAlpha',0.3)
            
            % data owtt
            subplot(3,1,1);
            hold on
            scatter(RECAP.data_time(index1),RECAP.data_owtt(index1),...
                markerSize,markerModemMap(node),markerShape(imd),'filled','MarkerFaceAlpha',0.3);
            
            % sim owtt
            subplot(3,1,2);
            hold on
            scatter(RECAP.sim_time(index1),RECAP.sim_owtt(index1),...
                markerSize,markerModemMap(node),markerShape(imd),'filled','MarkerFaceAlpha',0.3);
        end
    end
end

eof_bool = RECAP.eof_bool;
eof_time = RECAP.data_time;
[eof_time,order] = sort(eof_time);
eof_bool = eof_bool(order);

subplot(3,1,3);
axis tight
h_set_xy_bounds(eof_time,eof_time,RECAP.sim_gvel,RECAP.sim_gvel);
datetick('x');
title('group velocity | in situ prediction');
ylabel('c [m/s]');
xlabel('time [hr:mm]')
h_plot_patch(eof_bool,eof_time,[0 .025]);
grid on

subplot(3,1,1);
axis tight
h_set_xy_bounds(eof_time,eof_time,RECAP.data_owtt,RECAP.data_owtt);
datetick('x');
title('one way travel time | data');
ylabel('time [s]')
h_plot_patch(eof_bool,eof_time,[0 .025]);
grid on

subplot(3,1,2);
axis tight
h_set_xy_bounds(eof_time,eof_time,RECAP.sim_owtt,RECAP.sim_owtt);
datetick('x');
title('one way travel time | in situ prediction');
ylabel('time [s]')
h_plot_patch(eof_bool,eof_time,[0 .025]);
grid on

%% figure : bird's eye view
figure('Name','birdsEye','Renderer', 'painters', 'Position', [0 0 900 800]); clf
load p_legendDetails.mat

% bathymetry
minZ = round(min(plotBathy.zz(:)),1);
maxZ = round(max(plotBathy.zz(:)),1);
levels = minZ:20:maxZ;
[C,h] = contourf(plotBathy.xx,plotBathy.yy,plotBathy.zz,minZ:20:maxZ);
cmap = cmocean('-gray',numel(levels));
cmap = brighten(cmap,.2);
colormap(cmap);
shading flat
%t1 = clabel(C,h,'manual');
clabel(C,h,'LabelSpacing',1000,'color','w','fontweight','bold','BackgroundColor','k');
hold on

% line connections
for nx = 1:RECAP.num_events
    
    if RECAP.tx_z(nx) == zs
        txNode = RECAP.tag_tx{nx};
        plot([RECAP.rx_x(nx) RECAP.tx_x(nx)],[RECAP.rx_y(nx) RECAP.tx_y(nx)],...
        '--','color',markerModemMap(txNode),'linewidth',3);
    end
end

% plot rx nodes
for node = modem_labels
    node = node{1}; % change from cell to char
    for imd = modem_rx_depth
        
        index1 = find(strcmp(RECAP.tag_rx,node) & RECAP.rx_z == imd);
        index2 = find(strcmp(RECAP.tag_rx,node) & RECAP.rx_z == imd);
        index = union(index1,index2);
        
        if ~isempty(index)
            ixlgd = ixlgd + 1;
            rx_x = RECAP.rx_x(index);
            rx_y = RECAP.rx_y(index);
            Lgd(ixlgd) = scatter(rx_x,rx_y,1.5.*markerSize,markerModemMap(node),markerShape(imd),'filled');
            LgdStr{ixlgd} = [num2str(imd) 'm | ' node];
            
        else % check to see if TX was valid
            index1 = find(strcmp(RECAP.tag_tx,node) & RECAP.tx_z == imd);
            index2 = find(strcmp(RECAP.tag_tx,node) & RECAP.tx_z == imd);
            index = union(index1,index2);
            
            if ~isempty(index)
                ixlgd = ixlgd + 1;
                tx_x = [RECAP.tx_x(index1) RECAP.tx_x(index2)];
                tx_y = [RECAP.tx_y(index1) RECAP.tx_y(index2)];
                Lgd(ixlgd) = scatter(tx_x,tx_y,1.5.*markerSize,markerModemMap(node),markerShape(imd),'filled');
                LgdStr{ixlgd} = [num2str(imd) 'm | ' node];
            end
        end
    end
end

% tx connections in legend
tx_node = [RECAP.tag_tx RECAP.tag_tx];
tx_node = unique(tx_node);
for utn = tx_node
    ixlgd = ixlgd + 1;
    Lgd(ixlgd) = plot(NaN,NaN,'--','color',markerModemMap(utn{1}));
    LgdStr{ixlgd} = [' tx from ' utn{1}];
end

hold off
xlabel('x [m]')
ylabel('y [m]')
axis equal
%lb = legend(Lgd,LgdStr,'location','bestoutside');
%title(lb,'Nodes');
title(['Bird''s Eye View of Camp Seadragon, zs = ' num2str(zs) 'm'],'fontsize',18);

% h_printThesisPNG(sprintf('zs%u-birdseye',zs));