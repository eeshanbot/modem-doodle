%% main_plot_tobytest_by_event

% eeshan bhatt

%% prep workspace
clear; clc;

%% load toby test data by event
location = './data-tobytest-by-event/*.mat';
listing = dir(location);
num_listing = numel(listing);

%% loop through each listing

for iNL = 4
    
    figure(1); clf;
    
    % load events
    load([listing(iNL).folder '/' listing(iNL).name]);
    
    sim_range = h_get_nested_val_filter(event,'sim','range');
    
    owtt = h_get_nested_val_filter(event,'tag','owtt');
    sim_delay = h_get_nested_val_filter(event,'sim','delay');
    sim_gvel = h_get_nested_val_filter(event,'sim','gvel');
    
    tx_x = h_get_nested_val_filter(event,'tx','x');
    tx_y = h_get_nested_val_filter(event,'tx','y');
    tx_z = h_get_nested_val_filter(event,'tx','z');
    tx_loc = [tx_x; tx_y; tx_z];

    rx_x = h_get_nested_val_filter(event,'rx','x');
    rx_y = h_get_nested_val_filter(event,'rx','y');
    rx_z = h_get_nested_val_filter(event,'rx','z');
    rx_loc = [rx_x; rx_y; rx_z];
    
    dist3 = @(p,q) sqrt(  (p(1,:) - q(1,:)).^2 ...
                        + (p(2,:) - q(2,:)).^2 ...
                        + (p(3,:) - q(3,:)).^2 );
    
    gps_range = dist3(tx_loc,rx_loc);
    gvel = gps_range ./ owtt;
    
    %% figure: data
    subplot(5,3,[10 13]);
    scatter(owtt,sim_delay,100,'filled','MarkerFaceAlpha',0.3)
    grid on
    title('owtt [s]')
    set_xy_bounds(owtt,sim_delay,owtt,sim_delay);
    ylabel('simulated')
    xlabel('data')
    
    %% figure: simulation
    subplot(5,3,[11 14])
    scatter(gps_range,sim_range,100,'filled','MarkerFaceAlpha',0.3)
    hold on
    grid on
    title('range [m]')
    ylabel('simulated')
    xlabel('data')
    set_xy_bounds(gps_range,sim_range,gps_range,sim_range);
    
    %% figure: gvel
    subplot(5,3,[12 15])
    scatter(gvel,sim_gvel,100,'filled','MarkerFaceAlpha',0.3)
    title('horizontal group velocity [m/s]')
    ylabel('simulated')
    xlabel('data')
    grid on
    axis equal
    
end

%% figure locations in x,y
subplot(4,3,[1 4.5]);
hold on
for nx = 1:numel(rx_x)
    plot([rx_x(nx) tx_x(nx)],[rx_y(nx) tx_y(nx)],'color',[.5 .5 .5 0.02],'linewidth',7);
end
plot(rx_x,rx_y,'b*','markersize',15);
plot(tx_x,tx_y,'ro','markersize',15);
hold off
grid on
xlabel('x [m]')
ylabel('y [m]')
title([event(1).tag.name ' : ' num2str(length(event)) ' contacts'])
axis equal

%% figure for contacts in z

subplot(4,3,[2.5 6])
hold on
for nz = 1:numel(rx_z)
    plot([0 1 ],[tx_z(nz) rx_z(nz)],'-','color',[.5 .5 .5 .02],'linewidth',7)
    plot(0,tx_z(nz),'ro','markersize',15)
    plot(1,rx_z(nz),'b*','markersize',15)
end
grid on
ylabel('z [m]');
xticks([0 1])
xticklabels({'tx','rx'})
title([event(1).tag.tstr ' to ' event(end).tag.tstr]);
xlim([-0.2 1.2])
yticks([-90 -30 -20 0]);

%% helper function : set_xy_bounds(x1,x2);
function [] = set_xy_bounds(x1,x2,y1,y2)

min_xval = min([min(x1(:)) min(x2(:))]);
max_xval = max([max(x1(:)) max(x2(:))]);

min_yval = min([min(y1(:)) min(y2(:))]);
max_yval = max([max(y1(:)) max(y2(:))]);

xlim([min_xval max_xval]);
ylim([min_yval max_yval]);

axis square
end