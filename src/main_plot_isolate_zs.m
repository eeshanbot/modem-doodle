%% main_plot_ttrecap_tx.m
% eeshan bhatt

%% prep workspace
clear; clc; close all

lg_font_size = 14;

charcoalGray = [0.6 0.6 0.6];
alphaColor   = .035;

% depth_switch = [20 30 90];
zs = 30;

% load modem marker information
load p_modemMarkerDetails

%% load bathymetry data
bathyfile = '~/missions-lamss/cruise/icex20/data/environment/noaa_bathy_file.nc';
plotBathy = h_unpack_bathy(bathyfile);

%% load toby test data by experiment design
location = ['../data/tobytest-txz' num2str(zs) '*.mat'];
listing = dir(location);
num_listing = numel(listing);

% isolate eeof OFF
A = load([listing(1).folder '/' listing(1).name]);
BASE = h_unpack_experiment(A.experiment);

% isolate eeeof ON
A = load([listing(2).folder '/' listing(2).name]);
EEOF = h_unpack_experiment(A.experiment);

% create cell array of structure
BASE.title = 'baseval';
EEOF.title = 'eof';
CONFIG = {BASE EEOF};
clear BASE EEOF;

maxOwtt = max([CONFIG{1}.data_owtt CONFIG{2}.data_owtt]);
maxRange = max([CONFIG{1}.data_range CONFIG{2}.data_range])+100;

% loop through for modifications
for cfg = 1:2
    
    [CONFIG{cfg}.rx_x,CONFIG{cfg}.rx_y] = eb_ll2xy(CONFIG{cfg}.rx_lat,CONFIG{cfg}.rx_lon,plotBathy.olat,plotBathy.olon);
    [CONFIG{cfg}.tx_x,CONFIG{cfg}.tx_y] = eb_ll2xy(CONFIG{cfg}.tx_lat,CONFIG{cfg}.tx_lon,plotBathy.olat,plotBathy.olon);
end

%% figure : timeline

figure('Name','timeline','Renderer', 'painters', 'Position', [10 10 1700 1100]); clf;
load p_legendDetails.mat

for cfg = 1:2
    for node = CONFIG{cfg}.unique_rx
        node = node{1};
        for imd = modem_rx_depth
            index1 = find(strcmp(CONFIG{cfg}.tag_rx,node) & CONFIG{cfg}.rx_z == imd);
            
            if sum(index1) > 0
                % group velocity estimates (simulation)
                subplot(3,1,3);
                hold on
                scatter(CONFIG{cfg}.sim_time(index1),CONFIG{cfg}.sim_gvel(index1),...
                    markerSize,markerModemMap(node),markerShape(imd),'filled','MarkerFaceAlpha',0.3)
                
                % data owtt
                subplot(3,1,1);
                hold on
                scatter(CONFIG{cfg}.data_time(index1),CONFIG{cfg}.data_owtt(index1),...
                    markerSize,markerModemMap(node),markerShape(imd),'filled','MarkerFaceAlpha',0.3);
                
                % sim owtt
                subplot(3,1,2);
                hold on
                scatter(CONFIG{cfg}.sim_time(index1),CONFIG{cfg}.sim_owtt(index1),...
                    markerSize,markerModemMap(node),markerShape(imd),'filled','MarkerFaceAlpha',0.3);
            end
        end
    end
end

eof_bool = [CONFIG{1}.eof_bool CONFIG{2}.eof_bool];
eof_time = [CONFIG{1}.data_time CONFIG{2}.data_time];
[eof_time,order] = sort(eof_time);
eof_bool = eof_bool(order);

subplot(3,1,3);
axis tight
h_set_xy_bounds(eof_time,eof_time,CONFIG{1}.sim_gvel,CONFIG{2}.sim_gvel);
datetick('x');
title('group velocity | in situ prediction');
ylabel('c [m/s]');
xlabel('time [hr:mm]')
h_plot_patch(eof_bool,eof_time,[0 .025]);
grid on

subplot(3,1,1);
axis tight
h_set_xy_bounds(eof_time,eof_time,CONFIG{1}.data_owtt,CONFIG{2}.data_owtt);
datetick('x');
title('one way travel time | data');
ylabel('time [s]')
h_plot_patch(eof_bool,eof_time,[0 .025]);
grid on

subplot(3,1,2);
axis tight
h_set_xy_bounds(eof_time,eof_time,CONFIG{1}.sim_owtt,CONFIG{2}.sim_owtt);
datetick('x');
title('one way travel time | in situ prediction');
ylabel('time [s]')
h_plot_patch(eof_bool,eof_time,[0 .025]);
grid on

%% figure : bird's eye view
figure('Name','birdsEye','Renderer', 'painters', 'Position', [0 0 1200 1000]); clf
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
for cfg = 1:2
    for nx = 1:CONFIG{cfg}.num_events
        txNode = CONFIG{cfg}.tag_tx{nx};
        
        %plot([CONFIG{cfg}.rx_x(nx) CONFIG{cfg}.tx_x(nx)],[CONFIG{cfg}.rx_y(nx) CONFIG{cfg}.tx_y(nx)],...
        %'color',[1 1 1 .03],'linewidth',10,'HandleVisibility','off');
        plot([CONFIG{cfg}.rx_x(nx) CONFIG{cfg}.tx_x(nx)],[CONFIG{cfg}.rx_y(nx) CONFIG{cfg}.tx_y(nx)],...
            '--','color',markerModemMap(txNode),'linewidth',1);
    end
end

% plot rx nodes
for node = modem_labels
    node = node{1}; % change from cell to char
    for imd = modem_rx_depth
        
        index1 = find(strcmp(CONFIG{1}.tag_rx,node) & CONFIG{1}.rx_z == imd);
        index2 = find(strcmp(CONFIG{2}.tag_rx,node) & CONFIG{2}.rx_z == imd);
        index = union(index1,index2);
        
        if ~isempty(index)
            ixlgd = ixlgd + 1;
            rx_x = [CONFIG{1}.rx_x(index1) CONFIG{2}.rx_x(index2)];
            rx_y = [CONFIG{1}.rx_y(index1) CONFIG{2}.rx_y(index2)];
            Lgd(ixlgd) = scatter(rx_x,rx_y,1.5.*markerSize,markerModemMap(node),markerShape(imd),'filled');
            LgdStr{ixlgd} = [num2str(imd) 'm | ' node];
            
        else % check to see if TX was valid
            index1 = find(strcmp(CONFIG{1}.tag_tx,node) & CONFIG{1}.tx_z == imd);
            index2 = find(strcmp(CONFIG{2}.tag_tx,node) & CONFIG{2}.tx_z == imd);
            index = union(index1,index2);
            
            if ~isempty(index)
                ixlgd = ixlgd + 1;
                tx_x = [CONFIG{1}.tx_x(index1) CONFIG{2}.tx_x(index2)];
                tx_y = [CONFIG{1}.tx_y(index1) CONFIG{2}.tx_y(index2)];
                Lgd(ixlgd) = scatter(tx_x,tx_y,1.5.*markerSize,markerModemMap(node),markerShape(imd),'filled');
                LgdStr{ixlgd} = [num2str(imd) 'm | ' node];
            end
        end
    end
end

% tx connections in legend
tx_node = [CONFIG{1}.tag_tx CONFIG{2}.tag_tx];
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
lb = legend(Lgd,LgdStr,'location','bestoutside');
title(lb,'Nodes');
title(['Bird''s Eye View of Camp Seadragon, zs = ' num2str(zs) 'm'],'fontsize',20);