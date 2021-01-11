%% main_plot_ttrecap_tx.m
% eeshan bhatt

%% prep workspace
clear; clc;

lg_font_size = 14;
markerSize = 200;
alpha_grey      = [0.6 0.6 0.6];
alpha_color     = .035;

% depth_switch = [20 30 90];
zs = 20;

% tetradic colors to link modem colors
modem_colors = {[177 0 204]./256,[7 201 0]./256,[0 114 201]./256,[255 123 0]./256,[0 0 0]};
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
EXPERIMENT = {BASE EEOF};
clear BASE EEOF;

% loop through for modifications
for exp = 1:2
    
    % regrid sound speed for ray tracing
    Cq = interp1(EXPERIMENT{exp}.ssp_depth,EXPERIMENT{exp}.ssp_estimate,0:1:plotBathy.mean);
    [EXPERIMENT{exp}.raytraceR,EXPERIMENT{exp}.raytraceZ] = run_rt(Cq,0:1:plotBathy.mean,zs,max(EXPERIMENT{exp}.data_owtt));
    
    [EXPERIMENT{exp}.rx_x,EXPERIMENT{exp}.rx_y] = eb_ll2xy(EXPERIMENT{exp}.rx_lat,EXPERIMENT{exp}.rx_lon,plotBathy.olat,plotBathy.olon);
    [EXPERIMENT{exp}.tx_x,EXPERIMENT{exp}.tx_y] = eb_ll2xy(EXPERIMENT{exp}.tx_lat,EXPERIMENT{exp}.tx_lon,plotBathy.olat,plotBathy.olon);
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

for exp = 1:2
    
    % transparent connections
    for nx = 1:EXPERIMENT{exp}.num_events
        plot([EXPERIMENT{exp}.rx_x(nx) EXPERIMENT{exp}.tx_x(nx)],[EXPERIMENT{exp}.rx_y(nx) EXPERIMENT{exp}.tx_y(nx)],'color',[1 1 1 alpha_color],'linewidth',7,'HandleVisibility','off');
    end
    
    % plot rx nodes
    legendCount = 0;
    for node = EXPERIMENT{exp}.unique_rx
        node = node{1}; % change from cell to char
        for imd = rx_depth
            
            index = find(strcmp(EXPERIMENT{exp}.tag_rx,node) & EXPERIMENT{exp}.rx_z == imd);
            
            if sum(index) > 0
                legendCount = legendCount + 1;
                L(legendCount) = scatter(EXPERIMENT{exp}.rx_x(index),EXPERIMENT{exp}.rx_y(index),markerSize,markerModemMap(node),markerShape(imd),'filled');
                legendStr{legendCount} = [num2str(imd) 'm | ' node];
            end
        end
    end
    
    % plot TX in red circle
    L(legendCount) = scatter(EXPERIMENT{exp}.tx_x,EXPERIMENT{exp}.tx_y,2.*markerSize,'r','o');
    legendStr{legendCount} = [num2str(zs) 'm | tx'];
    
end
hold off
xlabel('x [m]')
ylabel('y [m]')
axis equal
legend(L,legendStr,'location','bestoutside')
title(['Bird''s Eye View of Camp Seadragon, zs = ' num2str(zs) 'm'],'fontsize',20);

%% figure 2: x/y drift over experiment time
figure(2); clf;

for ml = modem_labels
    ml = ml{1}; % cell array to character
    
    rec_xval = [];
    rec_yval = [];
    rec_date = [];
    
    for exp = 1:2
        tag_rx = EXPERIMENT{exp}.tag_rx;
        
        % grab data from this node
        index = find(strcmp(tag_rx,ml));
        
        rec_xval = [rec_xval EXPERIMENT{exp}.rx_x(index)];
        rec_yval = [rec_yval EXPERIMENT{exp}.rx_y(index)];
        
        rec_date  = [rec_date EXPERIMENT{exp}.data_time(index)];
    end
    
    % plot if exists
    if ~isempty(rec_xval)
        % sort in time
        [rec_date,index] = sort(rec_date);
        rec_xval = rec_xval(index); rec_xval = rec_xval - rec_xval(1);
        rec_yval = rec_yval(index); rec_yval = rec_yval - rec_yval(1);
        
        % xval scatter
        subplot(2,1,1)
        hold on
        scatter(rec_date,rec_xval,markerSize,markerModemMap(ml),'filled','MarkerFaceAlpha',5.*alpha_color);
        datetick('x');
        grid on
        ylabel('x-direction [m]');
        axis tight


        % yval scatter
        subplot(2,1,2)
        hold on
        scatter(rec_date,rec_yval,markerSize,markerModemMap(ml),'filled','MarkerFaceAlpha',5.*alpha_color);
        datetick('x');
        grid on
        xlabel('time [hh:mm]');
        ylabel('y-direction [m]');
        axis tight
    end
end
subplot(2,1,1); hold off
title('ice drift recorded from buoy GPS');

subplot(2,1,2); hold off




