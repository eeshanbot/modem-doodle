%% main_plot_ttrecap_tx.m
% eeshan bhatt

%% prep workspace
clear; clc;

lg_font_size = 14;
markerSize = 200;
alpha_grey      = [0.6 0.6 0.6];
alpha_color     = .035;

% depth_switch = [20 30 90];
zs = 30;

% tetradic colors to link modem colors
modem_colors = {[177 0 204]./256,[7 201 0]./256,[0 114 201]./256,[255 123 0]./256,[80 80 80]./256};
modem_labels = {'North','South','East','West','Camp'};
markerModemMap = containers.Map(modem_labels,modem_colors);

% modem depths
rx_depth = [20 30 90];
markerShape(20) = 's';
markerShape(30) = '^';
markerShape(90) = 'v';

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

figure(1); clf;

% bathymetry
minZ = round(min(plotBathy.zz(:)),1);
maxZ = round(max(plotBathy.zz(:)),1);
levels = minZ:20:maxZ;
[C,h] = contourf(plotBathy.xx,plotBathy.yy,plotBathy.zz,[minZ:20:maxZ]);
cmocean('-gray',numel(levels));
shading flat
clabel(C,h,'LabelSpacing',1200,'color','w','fontweight','bold','BackgroundColor','k');
hold on

for cfg = 1:2
    
    [ixlgd,Lgd,LgdStr] = lgd_init();
    
    % transparent connections
    for nx = 1:CONFIG{cfg}.num_events
        plot([CONFIG{cfg}.rx_x(nx) CONFIG{cfg}.tx_x(nx)],[CONFIG{cfg}.rx_y(nx) CONFIG{cfg}.tx_y(nx)],...
            'color',[1 1 1 alpha_color],'linewidth',10,'HandleVisibility','off');
    end
    
    % plot rx nodes
    for node = CONFIG{cfg}.unique_rx
        node = node{1}; % change from cell to char
        for imd = rx_depth
            
            index = find(strcmp(CONFIG{cfg}.tag_rx,node) & CONFIG{cfg}.rx_z == imd);
            
            if sum(index) > 0
                ixlgd = ixlgd + 1;
                Lgd(ixlgd) = scatter(CONFIG{cfg}.rx_x(index),CONFIG{cfg}.rx_y(index),markerSize,markerModemMap(node),markerShape(imd),'filled');
                LgdStr{ixlgd} = [num2str(imd) 'm | ' node];
            end
        end
    end
    
    % plot TX in red circle
    Lgd(ixlgd) = scatter(CONFIG{cfg}.tx_x,CONFIG{cfg}.tx_y,2.*markerSize,'r','o');
    LgdStr{ixlgd} = [num2str(zs) 'm | tx'];
end
hold off
xlabel('x [m]')
ylabel('y [m]')
axis equal
legend(Lgd,LgdStr,'location','bestoutside')
title(['Bird''s Eye View of Camp Seadragon, zs = ' num2str(zs) 'm'],'fontsize',20);

%% figure 2 : ray trace differences

figure(2); clf;
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
        plot(CONFIG{cfg}.raytraceR{nrz},CONFIG{cfg}.raytraceZ{nrz},'color',[alpha_grey 0.2],'handlevisibility','off');
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
        for imd = rx_depth
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

figure(3); clf;
[ixlgd,Lgd,LgdStr] = lgd_init();

for cfg = 1:2  
    for node = CONFIG{cfg}.unique_rx
        node = node{1};
        for imd = rx_depth
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
h_plot_patch(eof_bool,eof_time);
grid on

subplot(3,1,1);
axis tight
h_set_xy_bounds(eof_time,eof_time,CONFIG{1}.data_owtt,CONFIG{2}.data_owtt);
datetick('x');
title('one way travel time | data');
ylabel('time [s]')
h_plot_patch(eof_bool,eof_time);
grid on

subplot(3,1,2);
axis tight
h_set_xy_bounds(eof_time,eof_time,CONFIG{1}.sim_owtt,CONFIG{2}.sim_owtt);
datetick('x');
title('one way travel time | in situ prediction');
ylabel('time [s]')
h_plot_patch(eof_bool,eof_time);
grid on



%% helper function : lgd_init();
function [ixlgd,Lgd,LgdStr] = lgd_init()
ixlgd = 0;
Lgd = [];
LgdStr = {};
end


