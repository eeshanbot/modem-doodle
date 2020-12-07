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
    sim_gvel_std = h_get_nested_val_filter(event,'sim','gvelstd');
    sim_time = h_get_nested_val_filter(event,'sim','time');
    
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
    
    med_gvel = median(sim_gvel);
    std_gvel = std(sim_gvel);
    
    tag_tx = h_get_nested_val_filter(event,'tag','src');
    tag_rx = h_get_nested_val_filter(event,'tag','rec');
    unique_tag_rx = sort(unique(tag_rx));
end

%% tetradic color wheel
tetradic_colors = 1/256.* ...
    [0   0   0  ;   ...  % black
    5   119 177  ;   ...  % persimmon
    177 62  5 ;  ...  % eno
    120 177 5;  ...  % ironweed
    62  5   177];  ...  % shale blue
    
diff_shapes = {'o','>','^','<','v'};

modem_ids = [4 10 11 12 13];

for utr = unique_tag_rx
    indx = find(modem_ids == utr);
    marker_shape{utr} = diff_shapes{indx};
    marker_color{utr} = [tetradic_colors(indx,:)];
end


%% figure locations in x,y
subplot(4,3,[1 4.5]);
hold on
for nx = 1:numel(rx_x)
    plot([rx_x(nx) tx_x(nx)],[rx_y(nx) tx_y(nx)],'color',[.5 .5 .5 0.02],'linewidth',7,'HandleVisibility','off');
end

% plot by node
legendstr = {};
for utr = unique_tag_rx
    index = find(tag_rx == utr);
    scatter(rx_x(index(1)),rx_y(index(1)),250,marker_color{utr},marker_shape{utr},'filled');
    plot(tx_x(index),tx_y(index),'ro','markersize',25,'HandleVisibility','off');
    legendstr{end+1} = num2str(utr);
end
legend(legendstr,'location','best','fontsize',11);
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
    plot([0 1 ],[tx_z(nz) rx_z(nz)],'-','color',[.5 .5 .5 .05],'linewidth',7)
end

% plot by rx node
for utr = unique_tag_rx
    index = find(tag_rx == utr);
    rx_place = ones(size(index));
    scatter(rx_place,rx_z(index),250,marker_color{utr},marker_shape{utr},'filled')
    
    index = find(tag_tx == utr);
    tx_place = zeros(size(index));
    scatter(tx_place,tx_z(index),250,marker_color{utr},marker_shape{utr},'filled')
end

grid on
ylabel('z [m]');
xticks([0 1])
xticklabels({'tx','rx'})
title([event(1).tag.tstr ' to ' event(end).tag.tstr]);
xlim([-0.1 1.1])
yticks([-90 -30 -20 0]);

%% figure: data
subplot(5,3,[12 15]);

% plot by rx node
plot([0 10],[0 10.*med_gvel],'-','color',[0.3 0.3 0.3 0.3])
hold on
for utr = unique_tag_rx
    index = find(tag_rx == utr);
    scatter(owtt(index),gps_range(index),100,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',0.2)
end
hold off
grid on
title('in-situ data: range vs owtt')
set_xy_bounds(owtt,sim_delay,gps_range,sim_range);
ylabel('range [m]')
xlabel('owtt [s]')

%% figure: simulation
subplot(5,3,[11 14])
plot([0 10],[0 10.*med_gvel],'-','color',[0.3 0.3 0.3 0.3])
hold on
for utr = unique_tag_rx
    index = find(tag_rx == utr);
    scatter(sim_delay(index),sim_range(index),100,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',0.1)
end
hold off
grid on
title('in-situ estimate: range vs owtt')
ylabel('range [m]')
xlabel('owtt [s]')
set_xy_bounds(owtt, sim_delay,gps_range,sim_range);

%% figure: gvel -- timeline
subplot(5,3,[10 13])
hold on
for utr = unique_tag_rx
    index = find(tag_rx == utr);
    scatter(sim_time(index),sim_gvel(index),100,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',0.3)
end
hold off
title('estimated \nu')
ylabel('group velocity [m/s]')
xlabel('time')
grid on
datetick('x');
axis auto

%% helper function : set_xy_bounds(x1,x2);
function [] = set_xy_bounds(x1,x2,y1,y2)

min_xval = min([min(x1(:)) min(x2(:))]);
max_xval = max([max(x1(:)) max(x2(:))]);

min_yval = min([min(y1(:)) min(y2(:))]);
max_yval = max([max(y1(:)) max(y2(:))]);

xlim([min_xval max_xval]);
ylim([min_yval max_yval]);
end