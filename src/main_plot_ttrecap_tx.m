%% main_plot_ttrecap_tx.m
% eeshan bhatt

%% prep workspace
clear; clc;

lg_font_size = 14;
markerSize = 200;
alpha_grey      = [0.6 0.6 0.6];
alpha_color     = .035;

% depth_switch = [20 30 90];
zs = 90;

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

% figure(2); clf;
% [ixlgd,Lgd,LgdStr] = lgd_init();



%% helper function : lgd_init();
function [ixlgd,Lgd,LgdStr] = lgd_init()
ixlgd = 0;
Lgd = [];
LgdStr = {};
end


