%% main_plot_gvel_anomaly.m
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

figPos = [0 0 1500 720];

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
BASE.title = '{\itBaseval}';
EEOF.title = '{\itEOF}';
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

%% figure : range anomaly plot

figure('Name','rangeAnomaly','Renderer', 'painters', 'Position', figPos); clf;
hold on
load p_legendDetails.mat

% group velocity from ALL DATA
data_owtt = [CONFIG{1}.data_owtt CONFIG{2}.data_owtt];
data_range = [CONFIG{1}.data_range CONFIG{2}.data_range];
data_rxz = [CONFIG{1}.rx_z CONFIG{2}.rx_z];
data_rnode = [CONFIG{1}.tag_rx CONFIG{2}.tag_rx];
val_index = ~isnan([CONFIG{1}.sim_gvel CONFIG{2}.sim_gvel]);

mean_gvel = mean(data_range(val_index) ./ data_owtt(val_index),'omitnan');

%data_gvel.gvelall = data_range ./ data_owtt;
data_gvel.gvel      = data_range(val_index) ./ data_owtt(val_index);
data_gvel.mean      = mean(data_gvel.gvel,'omitnan');
data_gvel.med       = median(data_gvel.gvel,'omitnan');
data_gvel.std       = std(data_gvel.gvel,'omitnan');
data_gvel.err       = zeros(size(data_gvel.gvel));
data_gvel.range     = data_range(val_index);
data_gvel.owtt      = data_owtt(val_index);
data_gvel.rxnode    = [CONFIG{1}.tag_rx CONFIG{2}.tag_rx];
data_gvel.rxnode    = data_gvel.rxnode(val_index);
data_gvel.rxz       = [CONFIG{1}.rx_z CONFIG{2}.rx_z];
data_gvel.rxz       = data_gvel.rxz(val_index);
data_gvel.title     = 'data';
data_gvel.num       = sum(~isnan(data_gvel.gvel));
data_gvel.index     = val_index;

% group velocity from CONFIG 1 = BASE simulation
%                from CONFIG 2 = EEOF simulation
for cfg = 1:2
    val_cfg_index       = ~isnan(CONFIG{cfg}.sim_gvel);
    sim_gvel(cfg).gvel  = CONFIG{cfg}.sim_gvel(val_cfg_index);
    sim_gvel(cfg).mean  = mean(sim_gvel(cfg).gvel);
    sim_gvel(cfg).med   = median(sim_gvel(cfg).gvel);
    sim_gvel(cfg).std   = std(sim_gvel(cfg).gvel);
    sim_gvel(cfg).err   = CONFIG{cfg}.sim_gvel_std(val_cfg_index);
    sim_gvel(cfg).range = CONFIG{cfg}.sim_range(val_cfg_index);
    sim_gvel(cfg).owtt  = CONFIG{cfg}.sim_owtt(val_cfg_index);
    sim_gvel(cfg).rxnode = CONFIG{cfg}.tag_rx(val_cfg_index);
    sim_gvel(cfg).rxz   = CONFIG{cfg}.rx_z(val_cfg_index);
    sim_gvel(cfg).title = CONFIG{cfg}.title;
    sim_gvel(cfg).num   = sum(val_cfg_index);
    
    buff = numel(val_index) - numel(val_cfg_index);
    
    if cfg == 1
        sim_gvel(cfg).index = boolean([val_cfg_index zeros(size(1,buff))]);
    elseif cfg == 2
        sim_gvel(cfg).index = boolean([zeros(size(1,buff)) val_cfg_index]);
    end
end

G = [data_gvel sim_gvel];

for gg = 1:numel(G)
    
    subplot(1,3,gg)
    hold on
    
    Y1 = G(gg).mean - G(1).mean;
    Y2 = G(gg).std;
    
    % plot gvel +/- stds w/ a patch
    minT = min(data_owtt)-.09*range(data_owtt);
    maxT = max(data_owtt)+.09*range(data_owtt);
    pXval = [minT maxT maxT minT];
    pYval = [pXval(1:2).*(Y1 + Y2) pXval(3:4).*(Y1 - Y2)];
    p = patch(pXval,pYval,'w','handlevisibility','off');
    p.FaceColor = charcoalGray;
    p.EdgeColor = 'none';
    p.FaceAlpha = .137;
    
    % plot middle offset
    Lgd(1) = plot(pXval(1:2),Y1.*pXval(1:2),'-','color',charcoalGray,'linewidth',1);
    
    % add error
    Y3 = mean(G(gg).err,'omitnan')/2;
    
    plot(pXval(1:2),pXval(1:2).*(Y1 + Y2 + Y3),':','color',charcoalGray,'linewidth',1);
    plot(pXval(1:2),pXval(1:2).*(Y1 - Y2 - Y3),':','color',charcoalGray,'linewidth',1);
    
    for k = 1:numel(data_range)
        yval(k) = data_range(k) - mean_gvel.*data_owtt(k);
        
        scatter(data_owtt(k), yval(k),...
            markerSize,markerModemMap(data_rnode{k}),markerShape(data_rxz(k)),...
            'filled','MarkerFaceAlpha',0.1)
    end
    
    % plot black dots for ones that seed gvel calculation
    plot(G(gg).owtt,G(gg).range - mean_gvel .* G(gg).owtt,'.','color',[.4 .4 .4],'markersize',8)
    
    ymax(gg) = max( [yval G(gg).range - mean_gvel .* G(gg).owtt] );
    ymin(gg) = min( [yval G(gg).range - mean_gvel .* G(gg).owtt] );

    
    lgdstr = ['u=' num2str(G(gg).mean,'%2.1f') ' m/s'];
    lg = legend(Lgd,lgdstr,'location','northwest','fontsize',lg_font_size-2);
end

% make plot pretty (and useful)
for gg = 1:numel(G)
    subplot(1,3,gg);
    xbuff = .09.*range(data_owtt);
    xlim([min(data_owtt)-xbuff max(data_owtt)+xbuff])
    ylim([min(ymin) max(ymax)]);
    grid on
    if gg == 2
        title({['Range errors for source depth = ' num2str(zs) 'm, N = ' num2str(numel(data_gvel.range))],...
            ['n = ' num2str(G(gg).num) ' from ' G(gg).title]},'fontsize',15)
    else
        title({'    ',...
            ['n = ' num2str(G(gg).num) ' from ' G(gg).title]},'fontsize',15);
    end
end

subplot(1,3,1)
ylabel('range error [m]');

subplot(1,3,2);
xlabel('owtt [s]');

h_printThesisPNG(sprintf('zs%u-rangeError.png',zs));

%% figure : range anomaly plot by receiver depth

figure('Name','rangeAnomaly','Renderer', 'painters', 'Position', figPos); clf;
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
    data_gvel(k).range = data_range(val_index);
    data_gvel(k).owtt = data_owtt(val_index);
    data_gvel(k).rxnode   = data_rxnode(val_index);
    data_gvel(k).rxz      = data_rxz(val_index);
    data_gvel(k).title     = 'data';
    data_gvel(k).num      = sum(val_index);
    data_gvel(k).index = val_index;
    
    H(k).owtt = data_owtt(index1);
    H(k).range = data_range(index1);
    H(k).rxz = data_rxz(index1);
    H(k).rxnode = data_rxnode(index1);
    H(k).gvelMean = mean(data_gvel(k).gvel);
    
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
        sim_gvel(count).mean  = mean(sim_gvel(count).gvel);
        sim_gvel(count).med   = median(sim_gvel(count).gvel);
        sim_gvel(count).std   = std(sim_gvel(count).gvel);
        sim_gvel(count).err   = CONFIG{cfg}.sim_gvel_std(val_index);
        sim_gvel(count).range = CONFIG{cfg}.sim_range(val_index);
        sim_gvel(count).owtt  = CONFIG{cfg}.sim_owtt(val_index);
        sim_gvel(count).rxnode = CONFIG{cfg}.tag_rx(val_index);
        sim_gvel(count).rxz   = CONFIG{cfg}.rx_z(val_index);
        sim_gvel(count).title = CONFIG{cfg}.title;
        sim_gvel(count).num   = sum(val_index);
        sim_gvel(count).index = val_index;
    end
end

G = [data_gvel(1) sim_gvel(1:2) data_gvel(2) sim_gvel(3:4)];

for gg = 1:numel(G)
    
    subplot(2,3,gg)
    hold on
    
    if gg <=3
        dataRef = 1;
    else
        dataRef = 2;
    end
    
    Y1 = G(gg).mean - H(dataRef).gvelMean;
    Y2 = G(gg).std;
    
    % plot gvel +/- stds w/ a patch
    minT = min(data_owtt)-.09*range(data_owtt);
    maxT = max(data_owtt)+.09*range(data_owtt);
    pXval = [minT maxT maxT minT];
    pYval = [pXval(1:2).*(Y1 + Y2) pXval(3:4).*(Y1 - Y2)];
    p = patch(pXval,pYval,'w','handlevisibility','off');
    p.FaceColor = charcoalGray;
    p.EdgeColor = 'none';
    p.FaceAlpha = .137;
    
    % plot middle offset
    Lgd(1) = plot(pXval(1:2),Y1.*pXval(1:2),'-','color',charcoalGray,'linewidth',1);
    
    % add error
    Y3 = mean(G(gg).err,'omitnan')/2;
    
    plot(pXval(1:2),pXval(1:2).*(Y1 + Y2 + Y3),':','color',charcoalGray,'linewidth',1);
    plot(pXval(1:2),pXval(1:2).*(Y1 - Y2 - Y3),':','color',charcoalGray,'linewidth',1);
    
    for k = 1:numel(H(dataRef).owtt)
        yval = H(dataRef).range - H(dataRef).gvelMean.*H(dataRef).owtt;
        scatter(H(dataRef).owtt(k), yval(k),...
            markerSize,markerModemMap(H(dataRef).rxnode{k}),markerShape(H(dataRef).rxz(k)),...
            'filled','MarkerFaceAlpha',0.2)
    end
    
     % plot black dots for ones that seed gvel calculation
    plot(G(gg).owtt,G(gg).range - H(dataRef).gvelMean .* G(gg).owtt,'.','color',[.4 .4 .4],'markerSize',8);
    
    ymax(gg) = max([yval pYval])+3;
    ymin(gg) = min([yval pYval]);
    
    lgdstr = ['u=' num2str(G(gg).mean,'%2.1f') ' m/s'];
    lg = legend(Lgd,lgdstr,'location','northwest','fontsize',lg_font_size-3);
    
end

% make plot pretty
for gg = 1:numel(G)
    subplot(2,3,gg);
    
    if gg <=3
        dataRef = 1;
        ylim([min(ymin(1:3)) max(ymax(1:3))]);
    else
        dataRef = 2;
        ylim([min(ymin(4:6)) max(ymax(4:6))]);
    end
    
    xbuff = .09.*range(data_owtt);
    xlim([min(data_owtt)-xbuff max(data_owtt)+xbuff])
    grid on
    if gg == 2
        title({['Range error for source depth = ' num2str(zs) 'm, N = ' num2str(sum(gvelNanIndex))],...
            ['n = ' num2str(G(gg).num) ' from ' G(gg).title]},'fontsize',15)
    else
        title({'    ',...
            ['n = ' num2str(G(gg).num) ' from ' G(gg).title]},'fontsize',15);
    end
end

subplot(2,3,1)
ylabel({'receiver depth = 20,30m','range error [m]'},'fontsize',lg_font_size);

subplot(2,3,4);
ylabel({'receiver depth = 90m','range error [m]'},'fontsize',lg_font_size);

subplot(2,3,5);
xlabel('owtt [s]');

h_printThesisPNG(sprintf('zs%u-rangeError-depthBin.png',zs));
