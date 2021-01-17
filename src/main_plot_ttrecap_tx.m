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
EEOF.title = 'eeof';
CONFIG = {BASE EEOF};
clear BASE EEOF;

% loop through for modifications
for cfg = 1:2
    
    % regrid sound speed for ray tracing
    Cq = interp1(CONFIG{cfg}.ssp_depth,CONFIG{cfg}.ssp_estimate,0:1:plotBathy.mean);
    [CONFIG{cfg}.raytraceR,CONFIG{cfg}.raytraceZ] = run_rt(Cq,0:1:plotBathy.mean,zs,max(CONFIG{cfg}.data_owtt));
    
    [CONFIG{cfg}.rx_x,CONFIG{cfg}.rx_y] = eb_ll2xy(CONFIG{cfg}.rx_lat,CONFIG{cfg}.rx_lon,plotBathy.olat,plotBathy.olon);
    [CONFIG{cfg}.tx_x,CONFIG{cfg}.tx_y] = eb_ll2xy(CONFIG{cfg}.tx_lat,CONFIG{cfg}.tx_lon,plotBathy.olat,plotBathy.olon);
end

%% figure 1 : bird's eye view

figure('Renderer', 'painters', 'Position', [10 10 950 650]); clf;
load p_legendDetails.mat

% bathymetry
minZ = round(min(plotBathy.zz(:)),1);
maxZ = round(max(plotBathy.zz(:)),1);
levels = minZ:20:maxZ;
[C,h] = contourf(plotBathy.xx,plotBathy.yy,plotBathy.zz,[minZ:20:maxZ]);
cmap = cmocean('-gray',numel(levels));
cmap = brighten(cmap,.2);
colormap(cmap);
shading flat
clabel(C,h,'LabelSpacing',1200,'color','w','fontweight','bold','BackgroundColor','k');
hold on

% transparent connections
for cfg = 1:2
    for nx = 1:CONFIG{cfg}.num_events
        txNode = CONFIG{cfg}.tag_tx{nx};
        %plot([CONFIG{cfg}.rx_x(nx) CONFIG{cfg}.tx_x(nx)],[CONFIG{cfg}.rx_y(nx) CONFIG{cfg}.tx_y(nx)],...
            %'color',[1 1 1 .03],'linewidth',10,'HandleVisibility','off');
        plot([CONFIG{cfg}.rx_x(nx) CONFIG{cfg}.tx_x(nx)],[CONFIG{cfg}.rx_y(nx) CONFIG{cfg}.tx_y(nx)],...
            '-','color',markerModemMap(txNode),'linewidth',1.5,'HandleVisibility','off');
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
            Lgd(ixlgd) = scatter(rx_x,rx_y,markerSize,markerModemMap(node),markerShape(imd),'filled');
            LgdStr{ixlgd} = [num2str(imd) 'm | ' node];

        else % check to see if TX was valid
            index1 = find(strcmp(CONFIG{1}.tag_tx,node) & CONFIG{1}.tx_z == imd);
            index2 = find(strcmp(CONFIG{2}.tag_tx,node) & CONFIG{2}.tx_z == imd);
            index = union(index1,index2);
            
            if ~isempty(index)
                ixlgd = ixlgd + 1;
                tx_x = [CONFIG{1}.tx_x(index1) CONFIG{2}.tx_x(index2)];
                tx_y = [CONFIG{1}.tx_y(index1) CONFIG{2}.tx_y(index2)];
                Lgd(ixlgd) = scatter(tx_x,tx_y,markerSize,markerModemMap(node),markerShape(imd),'filled');
                LgdStr{ixlgd} = [num2str(imd) 'm | ' node];
            end
        end
    end
end

% plot TX in black circle
Lgd(ixlgd+1) = scatter(CONFIG{cfg}.tx_x,CONFIG{cfg}.tx_y,2.*markerSize,'k','o','LineWidth',2);
LgdStr{ixlgd+1} = [num2str(zs) 'm | tx'];

hold off
xlabel('x [m]')
ylabel('y [m]')
axis equal
lb = legend(Lgd,LgdStr,'location','bestoutside');
title(lb,'Nodes');
title(['Bird''s Eye View of Camp Seadragon, zs = ' num2str(zs) 'm'],'fontsize',20);

%% figure 2 : ray trace differences

figure('Renderer', 'painters', 'Position', [10 10 1200 800]); clf;
[ixlgd,Lgd,LgdStr] = lgd_init();

plotDepth = 400;

for cfg = 1:2
    
    subplot(2,4,cfg*4-3)
    plot(CONFIG{cfg}.ssp_estimate,CONFIG{cfg}.ssp_depth,'.-','markersize',20)
    set(gca,'ydir','reverse')
    grid on
    ylim([0 plotDepth]);
    xlabel('c [m/s]');
    ylabel('z [m/s]');
    title([CONFIG{cfg}.title ' ssp']);
    
    subplot(2,4,[cfg*4-2 cfg*4]);
    hold on
    num_rays = numel(CONFIG{cfg}.raytraceR);
    for nrz = 1:num_rays
        plot(CONFIG{cfg}.raytraceR{nrz},CONFIG{cfg}.raytraceZ{nrz},'color',[charcoalGray 0.2],'handlevisibility','off');
    end
    hold off
    title(['ray trace, z_0=' num2str(zs) ' m'])
    yticklabels([])
    axis tight
    ylim([0 plotDepth])
    xlim([0 1800])
    xlabel('range [m]');
    set(gca,'ydir','reverse')
    
    hold on
    ixlgd = ixlgd+1;
    Lgd(ixlgd) = scatter(0,zs,markerSize,'r','o','linewidth',2);
    LgdStr{ixlgd} = [num2str(zs) 'm | tx'];
    for node = CONFIG{cfg}.unique_rx
        node = node{1}; % change from cell to char
        for imd = modem_rx_depth
            index = find(strcmp(CONFIG{cfg}.tag_rx,node) & CONFIG{cfg}.rx_z == imd);
            if sum(index) > 0
                ixlgd = ixlgd + 1;
                Lgd(ixlgd) = scatter(CONFIG{cfg}.data_range(index),CONFIG{cfg}.rx_z(index),...
                    markerSize,markerModemMap(node),markerShape(imd),'filled');
                LgdStr{ixlgd} = [num2str(imd) 'm | ' node];
                
                total = sum(CONFIG{cfg}.rx_z(index) == imd);
                text(mean(CONFIG{cfg}.data_range(index)),imd+14,num2str(total),...
                    'HorizontalAlignment','center','VerticalAlignment','top','fontsize',12)
            end
        end
    end
    hold off
    
end

legend(Lgd,LgdStr,'location','SouthEast','fontsize',lg_font_size);

%% figure 3 : timeline

figure('Renderer', 'painters', 'Position', [10 10 1700 1100]); clf;
[ixlgd,Lgd,LgdStr] = lgd_init();

for cfg = 1:2
    for node = CONFIG{cfg}.unique_rx
        node = node{1};
        for imd = modem_rx_depth
            index = find(strcmp(CONFIG{cfg}.tag_rx,node) & CONFIG{cfg}.rx_z == imd);
            
            if sum(index) > 0
                % group velocity estimates (simulation)
                subplot(3,1,3);
                hold on
                scatter(CONFIG{cfg}.sim_time(index),CONFIG{cfg}.sim_gvel(index),...
                    markerSize,markerModemMap(node),markerShape(imd),'filled','MarkerFaceAlpha',0.3)
                
                % data owtt
                subplot(3,1,1);
                hold on
                scatter(CONFIG{cfg}.data_time(index),CONFIG{cfg}.data_owtt(index),...
                    markerSize,markerModemMap(node),markerShape(imd),'filled','MarkerFaceAlpha',0.3);
                
                % sim owtt
                subplot(3,1,2);
                hold on
                scatter(CONFIG{cfg}.sim_time(index),CONFIG{cfg}.sim_owtt(index),...
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
h_plot_patch(eof_bool,eof_time,[0.01 .025]);
grid on

%% helper function : lgd_init();
function [ixlgd,Lgd,LgdStr] = lgd_init()
ixlgd = 0;
Lgd = [];
LgdStr = {};
end


