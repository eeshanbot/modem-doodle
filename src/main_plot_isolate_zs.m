%% main_plot_ttrecap_tx.m
% eeshan bhatt

%% prep workspace
clear; clc; close all

lg_font_size = 14;

charcoalGray = [0.6 0.6 0.6];
alphaColor   = .035;

% depth_switch = [20 30 90];
zs = 20;

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
    
    % regrid sound speed for ray tracing
    Cq = interp1(CONFIG{cfg}.ssp_depth,CONFIG{cfg}.ssp_estimate,0:1:plotBathy.mean);
    [CONFIG{cfg}.raytraceR,CONFIG{cfg}.raytraceZ] = run_rt(Cq,0:1:plotBathy.mean,zs,maxOwtt);
    
    [CONFIG{cfg}.rx_x,CONFIG{cfg}.rx_y] = eb_ll2xy(CONFIG{cfg}.rx_lat,CONFIG{cfg}.rx_lon,plotBathy.olat,plotBathy.olon);
    [CONFIG{cfg}.tx_x,CONFIG{cfg}.tx_y] = eb_ll2xy(CONFIG{cfg}.tx_lat,CONFIG{cfg}.tx_lon,plotBathy.olat,plotBathy.olon);
end

%% figure 1 : bird's eye view
figure('Name','birdsEye','Renderer', 'painters', 'Position', [10 10 950 650]); clf
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
clabel(C,h,'LabelSpacing',1200,'color','w','fontweight','bold','BackgroundColor','k');
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

%% figure 2 : ray trace differences

figure('Name','ray trace','Renderer', 'painters', 'Position', [10 10 1700 900]); clf;

plotDepth = 400;

for cfg = 1:2
    
    subplot(2,4,cfg*4-3)
    plot(CONFIG{cfg}.ssp_estimate,CONFIG{cfg}.ssp_depth,'k.-','markersize',15)
    set(gca,'ydir','reverse')
    grid on
    ylim([0 plotDepth]);
    ylabel('z [m/s]');
    title([CONFIG{cfg}.title ' ssp']);
    if cfg == 2
        xlabel('c [m/s]');
    end
    
    subplot(2,4,[cfg*4-2 cfg*4]);
    hold on
    num_rays = numel(CONFIG{cfg}.raytraceR);
    for nrz = 1:num_rays
        plot(CONFIG{cfg}.raytraceR{nrz},CONFIG{cfg}.raytraceZ{nrz},'color',[charcoalGray 0.2],'handlevisibility','off');
    end
    hold off
    title(['ray trace, zs=' num2str(zs) ' m, tmax=' num2str(maxOwtt) ' s'])
    yticklabels([])
    axis tight
    xlim([0 maxRange]);
    ylim([0 plotDepth])
    set(gca,'ydir','reverse')
    
    if cfg == 2
        xlabel('range [m]');
    end
    
    hold on
    scatter(0,zs,markerSize,'k','s','linewidth',2);
    
    for node = CONFIG{cfg}.unique_rx
        node = node{1}; % change from cell to char
        for imd = modem_rx_depth
            index = find(strcmp(CONFIG{cfg}.tag_rx,node) & CONFIG{cfg}.rx_z == imd);
            if ~isempty(index)
                scatter(CONFIG{cfg}.data_range(index),CONFIG{cfg}.rx_z(index),...
                    markerSize,markerModemMap(node),markerShape(imd),'filled');
                
                % check by TX node
                
                tx_nodes = CONFIG{cfg}.tag_tx(index);
                unq_tx_nodes = unique(tx_nodes);
                
                for utn = unq_tx_nodes
                    
                    subindex = find((CONFIG{cfg}.rx_z == imd) & (strcmp(CONFIG{cfg}.tag_tx,utn{1})) & (strcmp(CONFIG{cfg}.tag_rx,node)));
                    text(mean(CONFIG{cfg}.data_range(subindex)),imd+14,num2str(numel(subindex)),...
                        'HorizontalAlignment','center','VerticalAlignment','top','fontsize',12,'color',markerModemMap(node))
                end
            end
        end
    end
    hold off
end

% make legend
load p_legendDetails.mat
subplot(2,4,[cfg*4-2 cfg*4]);
hold on
for node = modem_labels
    node = node{1};
    
    index1 = find(strcmp(CONFIG{1}.tag_rx,node));
    index2 = find(strcmp(CONFIG{2}.tag_rx,node));
    index = union(index1,index2);
    
    if ~isempty(index)
        
        % get tx depths
        zvals = [CONFIG{1}.rx_z(index1) CONFIG{2}.rx_z(index2)];
        unq_zvals = unique(zvals);
        
        for uz = unq_zvals
            ixlgd = ixlgd + 1;
            Lgd(ixlgd) = scatter(NaN,NaN,markerSize,markerModemMap(node),markerShape(uz),'filled');
            LgdStr{ixlgd} = [num2str(uz) ' m | ' node];
        end
    end
end

lg = legend(Lgd,LgdStr,'location','SouthWest','fontsize',12);
title(lg,'rx nodes');


%% figure 3 : timeline

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

%% figure 4 : range anomaly plot

figure('Name','rangeAnomaly','Renderer', 'painters', 'Position', [10 10 1400 800]); clf;
hold on
load p_legendDetails.mat

% group velocity from ALL DATA
data_owtt = [CONFIG{1}.data_owtt CONFIG{2}.data_owtt];
data_range = [CONFIG{1}.data_range CONFIG{2}.data_range];

val_index = ~isnan([CONFIG{1}.sim_gvel CONFIG{2}.sim_gvel]);

%data_gvel.gvelall = data_range ./ data_owtt;
data_gvel.gvel = data_range(val_index) ./ data_owtt(val_index);
data_gvel.mean = mean(data_gvel.gvel);
data_gvel.med  = median(data_gvel.gvel);
data_gvel.std  = std(data_gvel.gvel);
data_gvel.err  = zeros(size(data_gvel.gvel));
data_gvel.range = data_range;
data_gvel.owtt = data_owtt;
data_gvel.rxnode   = [CONFIG{1}.tag_rx CONFIG{2}.tag_rx];
data_gvel.rxz      = [CONFIG{1}.rx_z CONFIG{2}.rx_z];
data_gvel.title     = 'data';
data_gvel.num       = sum(val_index);

% group velocity from CONFIG 1 = BASE simulation
%                from CONFIG 2 = EEOF simulation
for cfg = 1:2
    val_index = ~isnan(CONFIG{cfg}.sim_gvel);
    sim_gvel(cfg).gvel  = CONFIG{cfg}.sim_gvel(val_index);
    sim_gvel(cfg).mean  = CONFIG{cfg}.gvel_mean;
    sim_gvel(cfg).med   = CONFIG{cfg}.gvel_med;
    sim_gvel(cfg).std   = std(CONFIG{cfg}.sim_gvel(val_index));
    sim_gvel(cfg).err   = CONFIG{cfg}.sim_gvel_std(val_index);
    sim_gvel(cfg).range = CONFIG{cfg}.sim_range(val_index);
    sim_gvel(cfg).owtt  = CONFIG{cfg}.sim_owtt(val_index);
    sim_gvel(cfg).rxnode = CONFIG{cfg}.tag_rx(val_index);
    sim_gvel(cfg).rxz   = CONFIG{cfg}.rx_z(val_index);
    sim_gvel(cfg).title = CONFIG{cfg}.title;
    sim_gvel(cfg).num   = sum(val_index);
end

G = [data_gvel sim_gvel];

for gg = 1:numel(G)
    
    subplot(1,3,gg)
    hold on
    
    Y1 = G(gg).mean - G(1).mean;
    Y2 = G(gg).std;
    
    % plot gvel +/- stds w/ a patch
    pXval = [0 5 5 0];
    pYval = [pXval(1:2).*(Y1 + Y2) pXval(3:4).*(Y1 - Y2)];
    p = patch(pXval,pYval,'w','handlevisibility','off');
    p.FaceColor = charcoalGray;
    p.EdgeColor = 'none';
    p.FaceAlpha = .137;
    
    % plot middle offset
    plot(pXval(1:2),Y1.*pXval(1:2),'-','color',charcoalGray,'linewidth',1);
   
    % add error
    Y3 = mean(G(gg).err,'omitnan')/2;
    
    plot(pXval(1:2),pXval(1:2).*(Y1 + Y2 + Y3),':','color',charcoalGray,'linewidth',1);
    plot(pXval(1:2),pXval(1:2).*(Y1 - Y2 - Y3),':','color',charcoalGray,'linewidth',1);
    
    for k = 1:numel(G(1).owtt)
        yval = G(1).range - G(gg).mean.*G(1).owtt;
        scatter(G(1).owtt(k), yval(k),...
            markerSize,markerModemMap(G(1).rxnode{k}),markerShape(G(1).rxz(k)),...
            'filled','MarkerFaceAlpha',0.1)
    end
    
    ymax(gg) = max(yval);
    ymin(gg) = min(yval);
    
end

% make plot pretty
for gg = 1:numel(G)
    subplot(1,3,gg);
    xbuff = .09.*range(G(1).owtt);
    xlim([min(G(1).owtt)-xbuff max(G(1).owtt)+xbuff])
    ylim([min(ymin) max(ymax)]);
    grid on
    if gg == 2
        title({['Range anomalies for zs=' num2str(zs) 'm'],['\nu_g | ' num2str(G(gg).num) ' from ' G(gg).title]},'fontsize',15)
    else
        title({'    ',['\nu_g | ' num2str(G(gg).num) ' from ' G(gg).title]},'fontsize',15);
    end
end

subplot(1,3,1)
ylabel('range anomaly [m]');

subplot(1,3,2);
xlabel('owtt [s]');

%% figure 5 : range anomaly plot

figure('Name','rangeAnomaly','Renderer', 'painters', 'Position', [10 10 1400 800]); clf;
hold on
load p_legendDetails.mat

% group velocity from ALL DATA
data_owtt   = [CONFIG{1}.data_owtt CONFIG{2}.data_owtt];
data_range  = [CONFIG{1}.data_range CONFIG{2}.data_range];
data_rxz    = [CONFIG{1}.rx_z CONFIG{2}.rx_z];
data_rxnode = [CONFIG{1}.tag_rx CONFIG{2}.tag_rx];
gvelNanIndex = ~isnan([CONFIG{1}.sim_gvel CONFIG{2}.sim_gvel]);

count = 0;
for k = 1:2
    % data from 20 & 30 m OR 90 m rx
    if k == 1
        index1 = data_rxz <= 30;
    else
        index1 = data_rxz > 30;
    end
    val_index = boolean(index1 .* gvelNanIndex);
    data_gvel(k).gvel = data_range(val_index) ./ data_owtt(val_index);
    data_gvel(k).mean = mean(data_gvel(k).gvel);
    data_gvel(k).med  = median(data_gvel(k).gvel);
    data_gvel(k).std  = std(data_gvel(k).gvel);
    data_gvel(k).err  = zeros(size(data_gvel(k).gvel));
    data_gvel(k).range = data_range(index1);
    data_gvel(k).owtt = data_owtt(index1);
    data_gvel(k).rxnode   = data_rxnode(index1);
    data_gvel(k).rxz      = data_rxz(index1);
    data_gvel(k).title     = 'data';
    data_gvel(k).num      = sum(val_index);
    
    % group velocity from CONFIG 1 = BASE simulation
    %                from CONFIG 2 = EEOF simulation
    for cfg = 1:2
        if k == 1
            index1 = CONFIG{cfg}.rx_z <= 30;
        else
            index1 = CONFIG{cfg}.rx_z > 30;
        end
        index2 = ~isnan(CONFIG{cfg}.sim_gvel);
        val_index = boolean(index1 .* index2);
        count = count + 1;
        sim_gvel(count).gvel  = CONFIG{cfg}.sim_gvel(val_index);
        sim_gvel(count).mean  = CONFIG{cfg}.gvel_mean;
        sim_gvel(count).med   = CONFIG{cfg}.gvel_med;
        sim_gvel(count).std   = std(CONFIG{cfg}.sim_gvel(val_index));
        sim_gvel(count).err   = CONFIG{cfg}.sim_gvel_std(val_index);
        sim_gvel(count).range = CONFIG{cfg}.sim_range(val_index);
        sim_gvel(count).owtt  = CONFIG{cfg}.sim_owtt(val_index);
        sim_gvel(count).rxnode = CONFIG{cfg}.tag_rx(val_index);
        sim_gvel(count).rxz   = CONFIG{cfg}.rx_z(val_index);
        sim_gvel(count).title = CONFIG{cfg}.title;
        sim_gvel(count).num   = sum(val_index);
    end
end

G = [data_gvel(1) sim_gvel(1:2) data_gvel(2) sim_gvel(3:4)];

for gg = 1:numel(G)
    
    subplot(2,3,gg)
    hold on
    
    if gg <=3
        dataRef = 1;
    else
        dataRef = 4;
    end
    
    Y1 = G(gg).mean - G(dataRef).mean;
    Y2 = G(gg).std;
    
    % plot gvel +/- stds w/ a patch
    minT = min(G(dataRef).owtt) - .1*range(G(dataRef).owtt);
    maxT = max(G(dataRef).owtt) + .1*range(G(dataRef).owtt);
    pXval = [minT maxT maxT minT];
    pYval = [pXval(1:2).*(Y1 + Y2) pXval(3:4).*(Y1 - Y2)];
    p = patch(pXval,pYval,'w','handlevisibility','off');
    p.FaceColor = charcoalGray;
    p.EdgeColor = 'none';
    p.FaceAlpha = .137;
    
    % plot middle offset
    plot(pXval(1:2),Y1.*pXval(1:2),'-','color',charcoalGray,'linewidth',1);
    
    % add error
    Y3 = mean(G(gg).err,'omitnan')/2;
    
    plot(pXval(1:2),pXval(1:2).*(Y1 + Y2 + Y3),':','color',charcoalGray,'linewidth',1);
    plot(pXval(1:2),pXval(1:2).*(Y1 - Y2 - Y3),':','color',charcoalGray,'linewidth',1);
    
    for k = 1:numel(G(dataRef).owtt)
        yval = G(dataRef).range - G(dataRef).mean.*G(dataRef).owtt;
        scatter(G(dataRef).owtt(k), yval(k),...
            markerSize,markerModemMap(G(dataRef).rxnode{k}),markerShape(G(dataRef).rxz(k)),...
            'filled','MarkerFaceAlpha',0.2)
    end
    
    ymax(gg) = max([yval pYval]);
    ymin(gg) = min([yval pYval]);
    
end

% make plot pretty
for gg = 1:numel(G)
    subplot(2,3,gg);
    
    if gg <=3
        dataRef = 1;
    else
        dataRef = 4;
    end
    
    xbuff = .09.*range(G(1).owtt);
    xlim([min(G(1).owtt)-xbuff max(G(1).owtt)+xbuff])
    ylim([min(ymin) max(ymax)]);
    grid on
    if gg == 2
        title({['Range anomalies for zs=' num2str(zs) 'm'],['\nu_g | ' num2str(G(gg).num) ' from ' G(gg).title]},'fontsize',15)
    else
        title({'    ',['\nu_g | ' num2str(G(gg).num) ' from ' G(gg).title]},'fontsize',15);
    end
end

subplot(2,3,1)
ylabel({'zr = 20,30m','range anomaly [m]'},'fontsize',lg_font_size);

subplot(2,3,4);
ylabel({'zr = 90m','range anomaly [m]'},'fontsize',lg_font_size);

subplot(2,3,5);
xlabel('owtt [s]');
