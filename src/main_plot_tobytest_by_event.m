%% main_plot_tobytest_by_event

% eeshan bhatt

%% prep workspace
clear; clc;

%% load toby test data by event
location = './data-tobytest-by-event/*.mat';
listing = dir(location);
num_listing = numel(listing);

set(0,'DefaultAxesFontSize',14)

%% loop through each listing

for iNL = 3
    
    figure(1); clf;
    
    % load events
    load([listing(iNL).folder '/' listing(iNL).name]);
    
    sim_range = get_nested_val_filter(event,'sim','range');
    filter_valid = sim_range > 0;
    sim_range = sim_range(filter_valid);
    
    owtt = get_nested_val_filter(event,'tag','owtt',filter_valid);
    gvel = get_nested_val_filter(event,'sim','gvel',filter_valid);
    
    tx_x = get_nested_val_filter(event,'tx','x',filter_valid);
    tx_y = get_nested_val_filter(event,'tx','y',filter_valid);
    tx_z = get_nested_val_filter(event,'tx','z',filter_valid);
    tx_loc = [tx_x; tx_y; tx_z];
    
    rx_x = get_nested_val_filter(event,'rx','x',filter_valid);
    rx_y = get_nested_val_filter(event,'rx','y',filter_valid);
    rx_z = get_nested_val_filter(event,'rx','z',filter_valid);
    rx_loc = [rx_x; rx_y; rx_z];
    
    dist3 = @(p,q) sqrt(  (p(1,:) - q(1,:)).^2 ...
                        + (p(2,:) - q(2,:)).^2 ... 
                        + (p(3,:) - q(3,:)).^2 );
                    
    gps_range = dist3(tx_loc,rx_loc);
    
    
    %% figure: owtt v range
    
    
    [f_owtt,xi_owtt]    = ksdensity(owtt,'support','positive','boundaryCorrection','reflection');
    [f_simrange,xi_simrange]  = ksdensity(sim_range,'support','positive','boundaryCorrection','reflection');
    [f_gpsrange,xi_gpsrange]      = ksdensity(gps_range,'support','positive','boundaryCorrection','reflection');
    [f_gvel,xi_gvel]    = ksdensity(gvel,'support','positive','boundaryCorrection','reflection');
    
    mle_gvel = gvel(f_gvel==max(f_gvel));

    
    subplot(4,1,1)
    plot(xi_owtt,f_owtt,'k');
    xlabel('owtt [s]')
    ylabel('$f( t )$','Interpreter','LaTeX')
    plot_stats(owtt,xi_owtt,f_owtt);
    title(event(1).tag.name);
    grid on
    xbounds = xlim();
    
    subplot(4,1,2);
    plot(xi_simrange,f_simrange,'k');
    plot_stats(sim_range,xi_simrange,f_simrange);
    xlabel('sim range [m]')
    ylabel('$f( r )$','Interpreter','LaTeX')
    grid on
    xlim(xbounds .* mle_gvel);
    
    subplot(4,1,3)
    plot(xi_gpsrange,f_gpsrange,'k');
    plot_stats(gps_range,xi_gpsrange,f_gpsrange);
    xlabel('gps range [m]');
    ylabel('$f( r )$','Interpreter','LaTeX')
    grid on
    xlim(xbounds .* mle_gvel);

    subplot(4,1,4)
    plot(xi_gvel,f_gvel,'k')
    plot_stats(gvel,xi_gvel,f_gvel);
    xlabel('group velocity [m/s]');
    ylabel('$f( \nu )$','Interpreter','LaTeX')
    grid on
end

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
plot([median_x median_x],[0 median_f],'o-','linewidth',1.5,'color',[153 51 153 200]/256);
plot([mean_x mean_x],[0 mean_f],'o-','linewidth',1.5,'color',[200 78 0 200]/256);
hold off
end