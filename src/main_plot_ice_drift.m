%% main_plot_ice_drift.m
% plots ice drift from ../data/tobytest-recap-clean.mat

%% prep workspace

clear; clc;

lg_font_size = 14;
markerSize = 50;
alpha_grey      = [0.6 0.6 0.6];
alpha_color     = .035;

% tetradic colors to link modem colors
modem_colors = {[177 0 204]./256,[7 201 0]./256,[0 114 201]./256,[255 123 0]./256};
modem_labels = {'North','South','East','West'};
markerModemMap = containers.Map(modem_labels,modem_colors);

% legend information
ixlgd = 0;
Lgd = [];
LgdStr = {};

%% load toby test data recap all
load '../data/tobytest-recap-clean.mat'
RECAP = h_unpack_experiment(event);

%% loop

figure(1); clf;

for node = modem_labels
    node = node{1}; % cell array to character
    
    ixlgd = ixlgd + 1;
    
    rx_index = find(strcmp(RECAP.tag_rx,node));
    rx_x = RECAP.rx_x(rx_index);
    rx_y = RECAP.rx_y(rx_index);
    rx_t = RECAP.data_time(rx_index);
        
    %     tx_index = find(strcmp(RECAP.tag_tx,node));
    %     tx_x = RECAP.tx_x(tx_index);
    %     tx_y = RECAP.tx_y(tx_index);
    %     tx_t = RECAP.data_time(tx_index);
    %
    %     xval = [rx_x tx_x];
    %     yval = [rx_y tx_y];
    %     tval = [rx_t tx_t];
    
    xval = rx_x;
    yval = rx_y;
    tval = rx_t;
    
    [tval,time_index] = sort(tval);
    xval = xval(time_index);
    yval = yval(time_index);
    
    % x subplot
    subplot(2,1,1)
    Lgd(ixlgd) = scatter(tval, xval - xval(1),markerSize,markerModemMap(node),'filled','MarkerFaceAlpha',0.3);
    LgdStr{ixlgd} = node;
    hold on
    grid on
    datetick('x');
    ylabel('x-dir drift [m]');
    axis tight
    
    % y subplot
    subplot(2,1,2);
    scatter(tval, yval - yval(1),markerSize,markerModemMap(node),'filled','MarkerFaceAlpha',0.3);
    hold on
    grid on
    datetick('x');
    xlabel('time [hr:mm]');
    ylabel('y-dir drift [m]')
    legend(Lgd,LgdStr);
    axis tight
    
    sgtitle({'Ice Floe Drift Recorded from Modem Buoy GPS',' '},'fontsize',22);
    
end

eof_bool = RECAP.eof_bool;
eof_time = RECAP.data_time;
tx_z = RECAP.tx_z;


[eof_time,idx] = sort(eof_time);
eof_bool = eof_bool(idx);

subplot(2,1,1);
plot_patch(eof_bool,eof_time,tx_z);

subplot(2,1,2);
plot_patch(eof_bool,eof_time,tx_z);


%% helper function : plot_patch
function [] = plot_patch(eof_bool,eof_time,tx_z)

% get ybounds
ybounds = ylim();

% figure out how many patches we neek
kindex = find(diff(eof_bool)~=0);

bool_open = eof_bool(1);
bool_close = eof_bool(end);

if bool_open
    kindex = [1 kindex];
end

if bool_close
    kindex = [kindex numel(eof_time)];
end

% loop through patches -- eeof ON
for k = 1:numel(kindex)/2
    
    patchTime = [eof_time(kindex(2*k-1)) eof_time(kindex(2*k))];
    
    src_depth = tx_z( kindex(2*k-1) : kindex(2*k) );
    zstr = ['zs = '];
    for uz = unique(src_depth)
        zstr = [zstr num2str(uz) ', '];
    end
    zstr = zstr(1:end-2);
    zstr = [zstr ' m'];
    
    buffer = 4;
    
    patchTime = [patchTime(1) patchTime patchTime(end)];
    patchVal = ybounds(2).*ones(size(patchTime))+1;
    patchVal(1) = ybounds(1)-1;
    patchVal(end) = ybounds(1)-1;
    p = patch(patchTime,patchVal,'w','handlevisibility','off');
    p.FaceColor = [0.7 0.7 0.7];
    p.EdgeColor = 'none';
    p.FaceAlpha = .2;
        
    text(patchTime(end),max(patchVal),zstr,'HorizontalAlignment','right','fontsize',10,'fontangle','italic','VerticalAlignment','bottom')
    %text(patchTime(end),ybounds(1)+1,'  BASEVAL','HorizontalAlignment','left','fontsize',12,'fontangle','italic')
end

% loop through blanks -- eeof OFF
for k = 1:numel(kindex)/2 - 1
    patchTime = [eof_time(kindex(2*k):kindex(2*k+1))];
    
    src_depth = tx_z( kindex(2*k) : kindex(2*k+1) );

    zstr = ['zs = '];
    for uz = unique(src_depth)
        zstr = [zstr num2str(uz) ', '];
    end
    zstr = zstr(1:end-2);
    zstr = [zstr ' m'];
    
    text(patchTime(end),max(patchVal),zstr,...
        'HorizontalAlignment','right','fontsize',10,'fontangle','italic','VerticalAlignment','bottom')
end
        
end