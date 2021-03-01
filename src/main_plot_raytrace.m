%% main_plot_raytrace.m
% plots raytrace information for toby test by source depth
% eeshan bhatt

%% prep workspace
clear; clc; close all;

lg_font_size = 14;

charcoalGray = [0.6 0.6 0.6];
alphaColor   = .035;

% depth_switch = [20 30 90];
zs = 20;

%% load important things

% modem marker information
load p_modemMarkerDetails

% eigenray table (precomputed)
load ~/.dropboxmit/icex_2020_mat/eigentable_flat

%% load toby test data by source depth
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
BASE.title = '{\it Baseval}';
EEOF.title = '{\it Chosen EOF}';
CONFIG = {BASE EEOF};
clear BASE EEOF;

sampleOWTT = mean([CONFIG{1}.data_owtt CONFIG{2}.data_owtt]) + 2.*std([CONFIG{1}.data_owtt CONFIG{2}.data_owtt]);
maxRange = max([CONFIG{1}.data_range CONFIG{2}.data_range])+100;

bathyfile = '~/missions-lamss/cruise/icex20/data/environment/noaa_bathy_file.nc';
plotBathy = h_unpack_bathy(bathyfile);
bottomDepth = 2680;

% loop through for modifications --- ray tracing and rx/tx moved x/y
% positions
for cfg = 1:2
    % regrid sound speed for ray tracing
    
    Cq = interp1(CONFIG{cfg}.ssp_depth,CONFIG{cfg}.ssp_estimate,0:1:bottomDepth);
    [CONFIG{cfg}.raytraceR,CONFIG{cfg}.raytraceZ] = run_rt(Cq,0:1:bottomDepth,zs,sampleOWTT+1);
        
    [CONFIG{cfg}.rx_x,CONFIG{cfg}.rx_y] = eb_ll2xy(CONFIG{cfg}.rx_lat,CONFIG{cfg}.rx_lon,plotBathy.olat,plotBathy.olon);
    [CONFIG{cfg}.tx_x,CONFIG{cfg}.tx_y] = eb_ll2xy(CONFIG{cfg}.tx_lat,CONFIG{cfg}.tx_lon,plotBathy.olat,plotBathy.olon);
end

%% figure : ray trace

% figure('Name','ray trace','Renderer', 'painters', 'Position', [10 10 1700 1000]); clf;
% 
% % max plot depth
% plotDepth = 300;
% 
% for cfg = 1:2
%     
%     % sound speed plot
%     subplot(2,10,[cfg*10-9 cfg*10-8])
%     plot(CONFIG{cfg}.ssp_estimate,CONFIG{cfg}.ssp_depth,'k.-','markersize',15)
%     set(gca,'ydir','reverse')
%     grid on
%     ylim([0 plotDepth]);
%     ylabel('z [m]');
%     title([CONFIG{cfg}.title ' ssp']);
%     if cfg == 2
%         xlabel('c [m/s]');
%     end
%     xlim([1432 1448])
%     
%     % plot rays
%     subplot(2,10,[cfg*10-7 cfg*10]);
%     hold on
%     num_rays = numel(CONFIG{cfg}.raytraceR);
%     for nrz = 1:num_rays
%         plot(CONFIG{cfg}.raytraceR{nrz},CONFIG{cfg}.raytraceZ{nrz},'color',[charcoalGray 0.1],'handlevisibility','off');
%     end
%     
%     % plot eigenrays
%     num_eigentable = numel(eigentable);
%     for ne = 1:num_eigentable
%         eof_status = double(eigentable{ne}.eof_status+1);
%         tx_z = double(eigentable{ne}.tx_z);
%         
%         if (eof_status == cfg && tx_z == zs)
%             
%             if ~strcmp(eigentable{ne}.ray,'None')
%             
%                 plot(eigentable{ne}.ray.r,eigentable{ne}.ray.z,...
%                     'color',[markerModemMap(eigentable{ne}.rx_node) 0.5],'linewidth',2,'handlevisibility','off')
%             end
%         end
%     end
%     
%     % decorate plot
%     hold off
%     title(sprintf('%s rays and eigenrays, zs=%u m',CONFIG{cfg}.title,zs));
%     yticks(0:50:300);
%     yticklabels([]);
%     axis tight
%     xlim([0 maxRange]);
%     ylim([0 plotDepth])
%     set(gca,'ydir','reverse')
%     box on
%     
%     % xlabel if bottom
%     if cfg == 2
%         xlabel('range [m]');
%     end
%     
%     % plot source
%     hold on
%     scatter(0,zs,markerSize,'k','s','linewidth',2);
%     
%     % plot modem shapes
%     for node = CONFIG{cfg}.unique_rx
%         node = node{1}; % change from cell to char
%         for imd = modem_rx_depth
%             index = find(strcmp(CONFIG{cfg}.tag_rx,node) & CONFIG{cfg}.rx_z == imd);
%             if ~isempty(index)
%                 scatter(CONFIG{cfg}.data_range(index),CONFIG{cfg}.rx_z(index),...
%                     markerSize,markerModemMap(node),markerShape(imd),'filled');
%                 
%                 % check by TX nodes 
%                 tx_nodes = CONFIG{cfg}.tag_tx(index);
%                 unq_tx_nodes = unique(tx_nodes);
%                 
%                 % report amount at each rx modem node
%                 for utn = unq_tx_nodes
%                     subindex = find((CONFIG{cfg}.rx_z == imd) & (strcmp(CONFIG{cfg}.tag_tx,utn{1})) & (strcmp(CONFIG{cfg}.tag_rx,node)));
%                     text(mean(CONFIG{cfg}.data_range(subindex)),imd+14,num2str(numel(subindex)),...
%                         'HorizontalAlignment','center','VerticalAlignment','top','fontsize',12,'color',markerModemMap(node))
%                 end
%             end
%         end
%     end
%     
%     % hold off for subplot
%     hold off
% end
% 
% %% make legend - manual is easier
% load p_legendDetails.mat
% subplot(2,10,[cfg*10-7 cfg*10]);
% hold on
% for node = modem_labels
%     node = node{1};
%     
%     index1 = find(strcmp(CONFIG{1}.tag_rx,node));
%     index2 = find(strcmp(CONFIG{2}.tag_rx,node));
%     index = union(index1,index2);
%     
%     if ~isempty(index)
%         % get tx depths
%         zvals = [CONFIG{1}.rx_z(index1) CONFIG{2}.rx_z(index2)];
%         unq_zvals = unique(zvals);
%         
%         for uz = unq_zvals
%             ixlgd = ixlgd + 1;
%             Lgd(ixlgd) = scatter(NaN,NaN,markerSize,markerModemMap(node),markerShape(uz),'filled');
%             LgdStr{ixlgd} = [num2str(uz) ' m | ' node];
%         end
%     end
% end
% 
% lg = legend(Lgd,LgdStr,'location','SouthWest','fontsize',12);
% title(lg,'rx nodes');
% 
% %% export
% h_printThesisPNG(sprintf('zs%u-raytrace.png',zs))

%% make plot of just the EOF sound speed
% figure : ray trace

figure('Name','raytrace-single','Renderer', 'painters', 'Position', [10 10 1700 600]); clf;

% max plot depth
plotDepth = 300;

for cfg = 2
    hold on
%     % sound speed plot
%     subplot(1,10,[1 2])
%     plot(CONFIG{cfg}.ssp_estimate,CONFIG{cfg}.ssp_depth,'k.-','markersize',15)
%     set(gca,'ydir','reverse')
%     grid on
%     ylim([0 plotDepth]);
%     ylabel('z [m]');
%     title([CONFIG{cfg}.title ' ssp']);
%     if cfg == 2
%         xlabel('c [m/s]');
%     end
%     xlim([1432 1456])
    
    % plot rays
    num_rays = numel(CONFIG{cfg}.raytraceR);
    for nrz = 1:num_rays
        plot(CONFIG{cfg}.raytraceR{nrz},CONFIG{cfg}.raytraceZ{nrz},'color',[charcoalGray 0.1],'handlevisibility','off');
    end
    % plot eigenrays
    num_eigentable = numel(eigentable);
    for ne = 1:num_eigentable
        eof_status = double(eigentable{ne}.eof_status+1);
        tx_z = double(eigentable{ne}.tx_z);
        
        if (eof_status == cfg && tx_z == zs)
            
            if ~strcmp(eigentable{ne}.ray,'None')
            
                plot(eigentable{ne}.ray.r,eigentable{ne}.ray.z,...
                    'color',[markerModemMap(eigentable{ne}.rx_node) 0.5],'linewidth',2,'handlevisibility','off')
            end
        end
    end
    
    % decorate plot
    title(sprintf('%s rays and eigenrays, source depth = %u m',CONFIG{cfg}.title,zs));
    yticks(0:50:300);
    axis tight
    xlim([0 maxRange]);
    ylim([0 plotDepth])
    set(gca,'ydir','reverse')
    box on
    ylabel('depth [m]');
    
    % xlabel if bottom
    if cfg == 2
        xlabel('range [m]');
    end
    
    % plot source
    scatter(0,zs,markerSize,'k','s','linewidth',2);
    
    % plot modem shapes
    for node = CONFIG{cfg}.unique_rx
        node = node{1}; % change from cell to char
        for imd = modem_rx_depth
            index = find(strcmp(CONFIG{cfg}.tag_rx,node) & CONFIG{cfg}.rx_z == imd);
            if ~isempty(index)
                scatter(CONFIG{cfg}.data_range(index),CONFIG{cfg}.rx_z(index),...
                    markerSize,markerModemMap(node),markerShape(imd),'filled');
                
                % check by TX nodes 
                tx_nodes = CONFIG{cfg}.tag_tx(index);
                unq_tx_nodes = unique(tx_nodes);
                
                % report amount at each rx modem node
                for utn = unq_tx_nodes
                    subindex = find((CONFIG{cfg}.rx_z == imd) & (strcmp(CONFIG{cfg}.tag_tx,utn{1})) & (strcmp(CONFIG{cfg}.tag_rx,node)));
                    text(mean(CONFIG{cfg}.data_range(subindex)),imd+14,num2str(numel(subindex)),...
                        'HorizontalAlignment','center','VerticalAlignment','top','fontsize',12,'color',markerModemMap(node))
                end
            end
        end
    end
    
    % hold off for subplot
    hold off
end

%% make legend - manual is easier
load p_legendDetails.mat
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