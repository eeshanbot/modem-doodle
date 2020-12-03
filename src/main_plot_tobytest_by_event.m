%% main_plot_tobytest_by_event

% eeshan bhatt

%% prep workspace
clear; clc;

%% load toby test data by event
location = './data-tobytest-by-event/*.mat';
listing = dir(location);
num_listing = numel(listing);

%% loop through each listing

for iNL = 5
    
    figure(1); clf;
    
    % load events
    load([listing(iNL).folder '/' listing(iNL).name]);
    
    sim_range = get_nested_val_filter(event,'sim','range');
    filter_valid = sim_range > 0;
    sim_range = sim_range(filter_valid);
    
    owtt = get_nested_val_filter(event,'tag','owtt',filter_valid);
    sim_delay = get_nested_val_filter(event,'sim','delay',filter_valid);
    sim_gvel = get_nested_val_filter(event,'sim','gvel',filter_valid);
    
    tx_x = get_nested_val_filter(event,'tx','x',filter_valid);
    tx_y = get_nested_val_filter(event,'tx','y',filter_valid);
    tx_z = get_nested_val_filter(event,'tx','z',filter_valid);
    tx_loc = [tx_x; tx_y; tx_z];
    holder = ones(length(event),1);

    rx_x = get_nested_val_filter(event,'rx','x',filter_valid);
    rx_y = get_nested_val_filter(event,'rx','y',filter_valid);
    rx_z = get_nested_val_filter(event,'rx','z',filter_valid);
    rx_loc = [rx_x; rx_y; rx_z];
    
    dist3 = @(p,q) sqrt(  (p(1,:) - q(1,:)).^2 ...
                        + (p(2,:) - q(2,:)).^2 ...
                        + (p(3,:) - q(3,:)).^2 );
    
    gps_range = dist3(tx_loc,rx_loc);
    gvel = gps_range ./ owtt;
    
    %% figure: owtt v range
    
    common_parameters = {'support','positive','bandwidth',0.025};

    [f_owtt,xi_owtt]            = ksdensity(owtt,common_parameters{:});
    [f_simowtt,xi_simowtt]      = ksdensity(sim_delay,common_parameters{:});
    
    [f_gpsrange,xi_gpsrange]    = ksdensity(gps_range,common_parameters{:});
    [f_simrange,xi_simrange]    = ksdensity(sim_range,common_parameters{:});
    
    [f_gvel,xi_gvel]            = ksdensity(gvel,common_parameters{:});
    [f_simgvel,xi_simgvel]      = ksdensity(sim_gvel,common_parameters{:});
    
    mle_gvel = xi_gvel(f_gvel==max(f_gvel));
    
    % -- OWTT -- %
    [f_owtt,f_simowtt,ybounds] = set_y_bounds(f_owtt,f_simowtt);
    xbounds = set_x_bounds(xi_owtt,xi_simowtt);
    
    subplot(5,3,10);
    
    plot(xi_owtt,f_owtt,'k');
    plot_stats(owtt,xi_owtt,f_owtt);
    grid on
    title('owtt{\it distribution}');
    set_xy_info('in situ data','k',xbounds,ybounds);
    
    subplot(5,3,13)
    plot(xi_simowtt,f_simowtt);
    plot_stats(sim_delay,xi_simowtt,f_simowtt);
    grid on
    set_xy_info('in situ simulation',[0 0.4470 0.7410],xbounds,ybounds);
    xlabel('[s]');
    
    % -- RANGE -- %
    [f_gpsrange,f_simrange,ybounds] = set_y_bounds(f_gpsrange,f_simrange);
    xbounds = set_x_bounds(xi_gpsrange,xi_simrange);
    
    subplot(5,3,11)
    plot(xi_gpsrange,f_gpsrange,'k');
    plot_stats(gps_range,xi_gpsrange,f_gpsrange);
    grid on
    title('range{\it distribution}')
    set_xy_info('in situ data','k',xbounds,ybounds);

    subplot(5,3,14);
    plot(xi_simrange,f_simrange);
    plot_stats(sim_range,xi_simrange,f_simrange);
    xlabel('[m]')
    grid on
    set_xy_info('in situ simulation',[0 0.4470 0.7410],xbounds,ybounds);
    
    % -- GVEL -- %
    [f_gvel,f_simgvel,ybounds] = set_y_bounds(f_gvel,f_simgvel);
    xbounds = set_x_bounds(xi_gvel,xi_simgvel);
    
    subplot(5,3,12)
    plot(xi_gvel,f_gvel,'k')
    plot_stats(gvel,xi_gvel,f_gvel);
    grid on
    title('horizontal group velocity{\it distribution}')
    set_xy_info('in situ data','k',xbounds,ybounds);

    
    subplot(5,3,15)
    plot(xi_simgvel,f_simgvel)
    plot_stats(sim_gvel,xi_simgvel,f_simgvel);
    grid on
    set_xy_info('in situ simulation',[0 0.4470 0.7410],xbounds,ybounds);
    xlabel('[m/s]');
end

%% figure locations in x,y
subplot(4,3,[1 4.5]);
plot(rx_x,rx_y,'b*');
hold on
plot(tx_x,tx_y,'ro');
plot([rx_x tx_x],[rx_y tx_y],'color',[0 0 0 0.1]);
hold off
grid on
xlabel('x [m]')
ylabel('y [m]')
title({[event(1).tag.name ' : ' num2str(length(event)) ' contacts'],[event(1).tag.tstr ' to ' event(end).tag.tstr]});
axis equal

subplot(4,3,[2.5 6])
hold on
for nz = 1:numel(rx_z)
    plot([0 1 ],[rx_z(nz) tx_z(nz)],'o-','color',[0 0 0 0.1])
end
grid on
ylabel('depth [m]');
xticks([0 1])
xticklabels({'tx','rx'})
xlim([-0.5 1.5])
yticks([-90 -30 -20 0]);

%% helper function : get_nested_val();
% get a nested value as an array over all structs
function [array] = get_nested_val_filter(obj,lvl1,lvl2,filter)
stuff = [obj.(lvl1)];
array = [stuff.(lvl2)];

if exist('filter','var')
    array = array(filter);
end

end

%% helper function : plot_stats();
% plots median value in red line
function [] = plot_stats(vals,xi,f)

median_x = median(vals);
mean_x = mean(vals);

% find where it intersects f
median_f = interp1(xi,f,median_x);
mean_f = interp1(xi,f,mean_x);

hold on
plot([median_x median_x],[0 median_f],'o-','linewidth',1,'color',[153 51 153 200]/256);
plot([mean_x mean_x],[0 mean_f],'o-','linewidth',1,'color',[200 78 0 200]/256);
hold off

% plot all vals projected onto xi,f
q = interp1(xi,f,vals);
hold on
plot(vals,q,'ko')
hold off

end

%% helper function : set_x_bounds(x1,x2);
function [bounds] = set_x_bounds(x1,x2)

minx1 = min(x1);
minx2 = min(x2);
minval = min(minx1,minx2);

maxx1 = max(x1);
maxx2 = max(x2);
maxval = max(maxx1,maxx2);

bounds = [minval maxval];

end

%% helper function : set_y_bounds(y1,y2);

function [y1,y2,bounds] = set_y_bounds(y1,y2)

maxy1 = max(y1);
maxy2 = max(y2);
maxval = max(maxy1,maxy2);

bounds = [0 1];
y1 = y1 ./ maxval;
y2 = y2 ./ maxval;

end

%% helper function : set_xy_info(lbl,color,bounds)
function [] = set_xy_info(lbl,color,xbounds,ybounds);
    xlim(xbounds); ylim(ybounds);
    yticks([0:0.25:1]);
    yticklabels([]);
    ylabel(lbl,'fontsize',12,'color',color);
end