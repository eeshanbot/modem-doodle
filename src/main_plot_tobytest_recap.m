%% main_plot_tobytest_by_design
% eeshan bhatt

%% prep workspace
clear; clc;

lg_font_size = 14;
marker_size = 200;
alpha_grey      = [0.6 0.6 0.6];
alpha_color     = .05;
set(0,'defaultAxesFontSize',18)

%% load toby test data by event
location = '../data/tobytest-tx*.mat';
listing = dir(location);
num_listing = numel(listing);

% from cruise.def --- March 10th 1530 (only used for plotting purposes)
olat = 71.17733;
olon = -142.40413;

%%  pick a toby test event!
for iNL = 1 % num_listing
    % load event
    load([listing(iNL).folder '/' listing(iNL).name]);
end

%% load data usefully with h_get_nested_val_filter

% one way travel time data
data_owtt = h_get_nested_val_filter(experiment,'tag','owtt');

% gps data to range
tx_x    = h_get_nested_val_filter(experiment,'tx','x');
tx_y    = h_get_nested_val_filter(experiment,'tx','y');
tx_z    = h_get_nested_val_filter(experiment,'tx','depth');

rx_x    = h_get_nested_val_filter(experiment,'rx','x');
rx_y    = h_get_nested_val_filter(experiment,'rx','y');
rx_z    = h_get_nested_val_filter(experiment,'rx','depth');

dist3 = @(px,py,pz,qx,qy,qz) ...
    sqrt((px - qx).^2 + ...
    (py - qy).^2 + ...
    (pz - qz).^2 );

data_range = dist3(tx_x,tx_y,tx_z,rx_x,rx_y,rx_z);
data_2D_range = dist3(tx_x,tx_y,zeros(size(tx_x)),rx_x,rx_y,zeros(size(rx_x)));

sim_owtt = h_get_nested_val_filter(experiment,'gvel','delay');
data_2D_range = data_2D_range;

% lat/lon data
tx_lat          = h_get_nested_val_filter(experiment,'tx','lat');
tx_lon          = h_get_nested_val_filter(experiment,'tx','lon');
rx_lat          = h_get_nested_val_filter(experiment,'rx','lat');
rx_lon          = h_get_nested_val_filter(experiment,'rx','lon');

data_time = h_get_nested_val_filter(experiment,'tag','time');
fprintf('%s to %s \n',datestr(data_time(1)),datestr(data_time(end)));

% get in-situ simulation data
sim_range       = h_get_nested_val_filter(experiment,'gvel','range');
sim_owtt        = h_get_nested_val_filter(experiment,'gvel','delay');
sim_gvel        = h_get_nested_val_filter(experiment,'gvel','gvel');
sim_gvel_std    = h_get_nested_val_filter(experiment,'gvel','gvelstd');
sim_time        = h_get_nested_val_filter(experiment,'gvel','time');

med_gvel = median(sim_gvel,'omitnan');

% get tx/rx tags
tag_tx          = h_get_nested_val_filter(experiment,'tag','src');
unique_tx       = sort(unique(tag_tx));
tag_rx          = h_get_nested_val_filter(experiment,'tag','rec');
unique_rx       = sort(unique(tag_rx));
num_events      = numel(tag_tx);

% sound speed estimate
toby_test_eof_bool = h_get_nested_val_filter(experiment,'tag','eeof');
eof_bool = toby_test_eof_bool(1);
OBJ_EOF = eb_read_eeof('eeof_itp_Mar2013.nc',true);
weights = [-10 -9.257 -1.023 3.312 -5.067 1.968 1.47].'; % manually written down weights from Toby's notes
ssp_estimate = OBJ_EOF.baseval + (OBJ_EOF.eofs * weights).*eof_bool;

% bathymetric data
bathyfile = '~/missions-lamss/cruise/icex20/data/environment/noaa_bathy_file.nc';
lat = ncread(bathyfile,'lat');
lon = ncread(bathyfile,'lon');
bathy = ncread(bathyfile,'Band1');
min_lat = 71.15; max_lat = 71.2;
min_lon = -142.48; max_lon = -142.33;
ilat1 = find(lat<=min_lat,1,'last');
ilat2 = find(lat>=max_lat,1,'first');
ilon1 = find(lon<=min_lon,1,'last');
ilon2 = find(lon>=max_lon,1,'first');
plot_lon = lon(ilon1:ilon2);
plot_lat = lat(ilat1:ilat2);
[latgrid,longrid] = meshgrid(plot_lat,plot_lon);

plotBathy.zz = abs(bathy(ilon1:ilon2,ilat1:ilat2));
plotBathy.mean = round(mean(plotBathy.zz(:)));
[plotBathy.xx,plotBathy.yy] = eb_ll2xy(latgrid,longrid,olat,olon);
[plotBathy.rxX,plotBathy.rxY] = eb_ll2xy(rx_lat,rx_lon,olat,olon);
[plotBathy.txX,plotBathy.txY] = eb_ll2xy(tx_lat,tx_lon,olat,olon);

% ray trace
zs = mode(tx_z);
Cq = interp1(OBJ_EOF.depth,ssp_estimate,0:1:plotBathy.mean);
[R,Z] = run_rt(Cq,0:1:plotBathy.mean,zs,max(data_owtt));

% tetradic colors to link modem colors
modem_colors = {[177 0 204]./256,[7 201 0]./256,[0 114 201]./256,[255 123 0]./256,[0 0 0]};
modem_labels = {'North','South','East','West','Camp'};
colorModemMap = containers.Map(modem_labels,modem_colors);

% modem depths
rx_depth = [30 90];
marker_shape(30) = '^';
marker_shape(90) = 'v';

%% figure : ssp, raytrace + contacts in range-independent space
figure(1); clf;
subplot(1,3,1)
plot(ssp_estimate,OBJ_EOF.depth,'o')
hold on
plot(OBJ_EOF.baseval,OBJ_EOF.depth,'color',alpha_grey);
hold off
title('sound speed estimate')
ylim([0 300])
grid on
set(gca,'ydir','reverse')
ylabel('z [m]')
xlabel('c [m/s]')

subplot(1,3,[1.9 3])
hold on
for nrz = 1:numel(R)
    plot(R{nrz},Z{nrz},'color',[alpha_grey 0.2],'handlevisibility','off');
end
hold off
title(['ray trace, z_0=' num2str(zs) ' m'])
yticklabels([])
axis tight
ylim([0 300])
xlim([0 2100])
xlabel('range [m]');
set(gca,'ydir','reverse')

% labels for legend
legendStr = {};
legendCount = 1;

hold on
L1(legendCount) = scatter(0,zs,marker_size,'r','o','linewidth',2);
legendStr{legendCount} = [num2str(zs) 'm | tx'];
for node = unique_rx
    node = node{1}; % change from cell to char
    for imd = rx_depth
        index = find(strcmp(tag_rx,node) & rx_z == imd);
        legendCount = legendCount + 1;
        L1(legendCount) = scatter(data_2D_range(index),rx_z(index),...
            marker_size,colorModemMap(node),marker_shape(imd),'filled');
        legendStr{legendCount} = [num2str(imd) 'm | ' node];
        
        total = sum(rx_z(index) == imd);
        text(mean(data_2D_range(index)),imd+10,num2str(total),'HorizontalAlignment','center','fontsize',12)
    end
end
hold off

legend(L1,legendStr,'location','SouthEast','fontsize',lg_font_size);

%% figure locations in x,y

figure(2); clf;

minZ = round(min(plotBathy.zz(:)),1);
maxZ = round(max(plotBathy.zz(:)),1);
levels = minZ:20:maxZ;
[C,h] = contourf(plotBathy.xx,plotBathy.yy,plotBathy.zz,[minZ:20:maxZ]);
cmocean('-gray',numel(levels));
shading flat

clabel(C,h,'LabelSpacing',1200,'color','w','fontweight','bold','BackgroundColor','k');

hold on
for nx = 1:num_events
    plot([plotBathy.rxX(nx) plotBathy.txX(nx)],[plotBathy.rxY(nx) plotBathy.txY(nx)],'color',[1 1 1 alpha_color],'linewidth',7,'HandleVisibility','off');
end

legendCount = 1;
L(legendCount) = scatter(plotBathy.txX,plotBathy.txY,marker_size,'r','o');

for node = unique_rx
    node = node{1}; % change from cell to char
    for imd = rx_depth
        legendCount = legendCount + 1;
        index = find(strcmp(tag_rx,node) & rx_z == imd);
        L(legendCount) = scatter(plotBathy.rxX(index),plotBathy.rxY(index),marker_size,colorModemMap(node),marker_shape(imd),'filled');
    end
end
hold off
xlabel('x [m]')
ylabel('y [m]')
title('Bird''s Eye View of Camp Seadragon with Bathymetry [m]');

legend(L,legendStr,'location','northwest','fontsize',lg_font_size);

%% figure: range vs owtt -- by gvel anomaly
figure(3); clf;

data_rangeGvelAnomaly = data_range - med_gvel.*data_owtt;
sim_rangeGvelAnomaly  = sim_range - med_gvel.*sim_owtt;

% data
subplot(1,2,1);

% plot zero line
plot([0 10],[0 0],'-','color',[0 0 0 0.5]);
% plot by rx
hold on
for node = unique_rx
    node = node{1}; % change from cell to char
    for imd = rx_depth
        index = find(strcmp(tag_rx,node) & rx_z == imd);
        scatter(data_owtt(index),data_rangeGvelAnomaly(index)...
            ,marker_size,colorModemMap(node),marker_shape(imd),'filled','MarkerFaceAlpha',2.*alpha_color)
    end
end
hold off
grid on
title('in-situ data: range vs owtt')
h_set_xy_bounds(data_owtt,sim_owtt,data_rangeGvelAnomaly,sim_rangeGvelAnomaly);
title('{\it data} range anomaly')
str = sprintf('median group velocity = %3.1f m/s',med_gvel);
legend(str,'fontsize',lg_font_size-1,'location','south')
xlabel('one way travel time [s]');
ylabel('range anomaly [m]');

% prediction
subplot(1,2,2);
plot([0 10],[0 0],'-','color',[0 0 0 0.5]);
hold on
for node = unique_rx
    node = node{1}; % change from cell to char  
    for imd = rx_depth
        index = find(strcmp(tag_rx,node) & rx_z == imd);
        scatter(sim_owtt(index),sim_rangeGvelAnomaly(index),...
            marker_size,colorModemMap(node),marker_shape(imd),'filled','MarkerFaceAlpha',2.*alpha_color)
    end
end
hold off
grid on
title('{\it prediction} range anomaly')
ylabel('range anomaly [m]')
xlabel('one way travel time [s]')
h_set_xy_bounds(data_owtt, sim_owtt,data_rangeGvelAnomaly,sim_rangeGvelAnomaly);

%% figure: timeline
figure(4); clf

% gvel -- timeline
subplot(3,1,1);
hold on
for node = unique_rx
    node = node{1}; % change from cell to char
    for imd = rx_depth
        index = find(strcmp(tag_rx,node) & rx_z == imd);
        scatter(sim_time(index),sim_gvel(index),marker_size,colorModemMap(node),marker_shape(imd),'filled','MarkerFaceAlpha',0.3,'handlevisibility','off')
    end
end
hline(med_gvel,'color',[0.3 0.3 0.3 0.3]);
hold off
if eof_bool
    eof_str = 'on';
else
    eof_str = 'off';
end
title(['predicted horizontal group velocity, EOF = ' eof_str],'fontsize',lg_font_size+1)
ylabel('\nu_g [m/s]')
grid on
datetick('x');
h_set_xy_bounds(data_time,sim_time,sim_gvel,sim_gvel);

% data owtt -- timeline
subplot(3,1,2)
hold on
for node = unique_rx
    node = node{1}; % change from cell to char
    for imd = rx_depth
        index = find(strcmp(tag_rx,node) & rx_z == imd);
        scatter(data_time(index),data_owtt(index),marker_size,colorModemMap(node),marker_shape(imd),'filled','MarkerFaceAlpha',0.3)
    end
end
hold off
datetick('x');
grid on
title('in-situ data: owtt','fontsize',lg_font_size+1)
ylabel('[s]')
h_set_xy_bounds(data_time,sim_time,data_owtt,sim_owtt)

% sim owtt -- timeline
subplot(3,1,3)
hold on
for node = unique_rx
    node = node{1}; % change from cell to char
    for imd = rx_depth
        index = find(strcmp(tag_rx,node) & rx_z == imd);
        scatter(sim_time(index),sim_owtt(index),marker_size,colorModemMap(node),marker_shape(imd),'filled','MarkerFaceAlpha',0.3)
    end
end
hold off
datetick('x');
grid on
title('in-situ prediction: owtt','fontsize',lg_font_size+1)
ylabel('[s]')
h_set_xy_bounds(data_time,sim_time,data_owtt,sim_owtt)
xlabel('time [hr:mm]');