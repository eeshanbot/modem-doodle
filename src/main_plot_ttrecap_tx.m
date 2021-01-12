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

%% figure 2 : x/y drift over experiment time
% figure(2); clf;
% [ixlgd,Lgd,LgdStr] = lgd_init();
% 
%     src_status  = boolean([]);
%     src_date = [];
% 
% for ml = modem_labels
%     ml = ml{1}; % cell array to character
%     
%     rec_xval = [];
%     rec_yval = [];
%     rec_date = [];
%     
%     for cfg = 1:2
%         % ping rx
%         tag_rx = CONFIG{cfg}.tag_rx;
%         
%         % grab data from this node
%         index = find(strcmp(tag_rx,ml));
%         
%         rec_xval = [rec_xval CONFIG{cfg}.rx_x(index)];
%         rec_yval = [rec_yval CONFIG{cfg}.rx_y(index)];
%         
%         rec_date  = [rec_date CONFIG{cfg}.data_time(index)];
%         
%         % ping tx
%         tag_tx = CONFIG{cfg}.tag_tx;
%         index = find(strcmp(tag_tx,ml));
%         if ~isempty(index)
%             rec_xval = [rec_xval CONFIG{cfg}.tx_x(index)];
%             rec_yval = [rec_yval CONFIG{cfg}.tx_y(index)];
%             rec_date = [rec_date CONFIG{cfg}.data_time(index)];
%             
%             % for patch --- experiment status
%             src_status = [src_status CONFIG{cfg}.eof_bool(index)];
%             src_date = [src_date CONFIG{cfg}.data_time(index)];
%         end
%     end
%     
%     % plot if exists
%     if ~isempty(rec_xval)
%         ixlgd = ixlgd + 1;
%         % sort in time
%         [rec_date,index] = sort(rec_date);
%         rec_xval = rec_xval(index); rec_xval = rec_xval - rec_xval(1);
%         rec_yval = rec_yval(index); rec_yval = rec_yval - rec_yval(1);
%         
%         k = 20 .* 1/60 .* 1/24; % X min moving average in days
%         rec_xval_fit = movmean(rec_xval,k,'SamplePoints',rec_date);
%         rec_yval_fit = movmean(rec_yval,k,'Samplepoints',rec_date);  
%         
%         % xval scatter
%         subplot(2,1,1)
%         hold on
%         Lgd(ixlgd) = scatter(rec_date,rec_xval,markerSize/2,markerModemMap(ml),'filled','MarkerFaceAlpha',10.*alpha_color);
%         LgdStr{ixlgd} = ml;
%         plot(rec_date,rec_xval_fit,'-','linewidth',3,'color',[markerModemMap(ml) 10.*alpha_color]);
%         datetick('x');
%         grid on
%         ylabel('x-direction [m]');
%         axis tight
% 
%         % yval scatter
%         subplot(2,1,2)
%         hold on
%         scatter(rec_date,rec_yval,markerSize/2,markerModemMap(ml),'filled','MarkerFaceAlpha',10.*alpha_color);
%         plot(rec_date,rec_yval_fit,'-','linewidth',3,'color',[markerModemMap(ml) 10.*alpha_color]);
%         datetick('x');
%         grid on
%         xlabel('time [hh:mm]');
%         ylabel('y-direction [m]');
%         axis tight
%     end
% end
% 
% subplot(2,1,1); 
% hold off
% title('Ice Floe Drift Recorded from Modem Buoy GPS');
% plot_patch(src_date(src_status));
% 
% 
% subplot(2,1,2);
% hold off
% legend(Lgd,LgdStr,'location','bestoutside');
% plot_patch(src_date(src_status));

%% figure 3 : ray trace differences

% figure(3); clf;
% [ixlgd,Lgd,LgdStr] = lgd_init();



%% helper function : lgd_init();
function [ixlgd,Lgd,LgdStr] = lgd_init()
ixlgd = 0;
Lgd = [];
LgdStr = {};
end

%% helper function : plot_patch
function [] = plot_patch(patchTime)

% get ybounds
ybounds = ylim();

patchTime = [patchTime(1) patchTime patchTime(end)];
patchVal = ybounds(2).*ones(size(patchTime));
patchVal(1) = ybounds(1);
patchVal(end) = ybounds(1);
p = patch(patchTime,patchVal,'w');
p.FaceColor = [0.7 0.7 0.7];
p.EdgeColor = 'none';
p.FaceAlpha = .2;

text(patchTime(end),ybounds(1)+1,'EOF   ','HorizontalAlignment','right','fontsize',12,'fontangle','italic')
text(patchTime(end),ybounds(1)+1,'  BASEVAL','HorizontalAlignment','left','fontsize',12,'fontangle','italic')

end


