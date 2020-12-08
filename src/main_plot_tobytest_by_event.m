%% main_plot_tobytest_by_event

% eeshan bhatt

%% prep workspace
clear; clc;

lg_font_size = 12;

%% load toby test data by event
location = './data-tobytest-by-event/*.mat';
listing = dir(location);
num_listing = numel(listing);

%% loop through each listing

for iNL = 4
    
    figure(1); clf;
    
    % load event
    load([listing(iNL).folder '/' listing(iNL).name]);
    
    % one way travel time data
    data_owtt = h_get_nested_val_filter(event,'tag','owtt');
    
    % gps data to range
    tx_x    = h_get_nested_val_filter(event,'tx','x');
    tx_y    = h_get_nested_val_filter(event,'tx','y');
    tx_z    = h_get_nested_val_filter(event,'tx','z');
    
    rx_x    = h_get_nested_val_filter(event,'rx','x');
    rx_y    = h_get_nested_val_filter(event,'rx','y');
    rx_z    = h_get_nested_val_filter(event,'rx','z');
    
    dist3 = @(px,py,pz,qx,qy,qz) ...
        sqrt((px - qx).^2 + ...
        (py - qy).^2 + ...
        (pz - qz).^2 );
    
    data_range = dist3(tx_x,tx_y,tx_z,rx_x,rx_y,rx_z);
    
    % filter real data to pull simulated data
    % realistic bounds (>0.2 s AND > 500 m);
    t_filter = data_owtt >= 0.2;
    r_filter = data_range >= 500;
    filter = and(t_filter,r_filter);
    
    sim_owtt = h_get_nested_val_filter(event,'simMacrura','delay');
    s_filter = sim_owtt > 0.2;
    filter = and(filter,s_filter);
    
    % re-index
    data_owtt = data_owtt(filter);
    data_range = data_range(filter);
    tx_x = tx_x(filter);
    tx_y = tx_y(filter);
    tx_z = tx_z(filter);
    rx_x = rx_x(filter);
    rx_y = rx_y(filter);
    rx_z = rx_z(filter);
    
    data_time = h_get_nested_val_filter(event,'tag','time',filter);
    
    % get in-situ simulation data
    sim_range       = h_get_nested_val_filter(event,'simMacrura','range',filter);
    sim_owtt        = h_get_nested_val_filter(event,'simMacrura','delay',filter);
    sim_gvel        = h_get_nested_val_filter(event,'simMacrura','gvel',filter);
    sim_gvel_std    = h_get_nested_val_filter(event,'simMacrura','gvelstd',filter);
    sim_time        = h_get_nested_val_filter(event,'simMacrura','time',filter);
    
    med_gvel = median(sim_gvel);
    std_gvel = std(sim_gvel);
    
    tag_tx          = h_get_nested_val_filter(event,'tag','src',filter);
    unique_tag_tx   = sort(unique(tag_tx));
    
    tag_rx          = h_get_nested_val_filter(event,'tag','rec',filter);
    unique_tag_rx   = sort(unique(tag_rx));
    
    exp_modem_id    = union(unique_tag_rx,unique_tag_tx);
    
    num_events      = sum(filter);
    alpha_color     = 2./num_events;
    alpha_grey      = [0.6 0.6 0.6];
end

%% tetradic color wheel
tetradic_colors = 1/256.* ...
    [0   0   0  ;   ...  % black
    5   119 177  ;   ...  % persimmon
    177 62  5 ;  ...  % eno
    120 177 5;  ...  % ironweed
    62  5   177];  ...  % shale blue
    
diff_shapes = {'o','>','^','<','v'};

modem_id = [4 10 11 12 13];

for mi = modem_id
    indx = find(modem_id == mi);
    marker_shape{mi} = diff_shapes{indx};
    marker_color{mi} = [tetradic_colors(indx,:)];
end


%% figure locations in x,y
subplot(4,3,[1 4]);
hold on
for nx = 1:num_events
    plot([rx_x(nx) tx_x(nx)],[rx_y(nx) tx_y(nx)],'color',[alpha_grey alpha_color],'linewidth',7,'HandleVisibility','off');
end

% plot by rx/tx node
legendStr = {};
legendCount = 0; 
for node = exp_modem_id
    
    legendCount = legendCount + 1;
    
    irx = find(tag_rx == node);
    if ~isempty(irx)
        L(legendCount) = scatter(rx_x(irx),rx_y(irx),250,marker_color{node},marker_shape{node},'filled');
        legendStr{end+1} = num2str(node);
    end
    
    itx = find(tag_tx == node);
    if ~isempty(itx)
        L(legendCount) = scatter(tx_x(itx),tx_y(itx),250,marker_color{node},marker_shape{node},'filled');
        if ~contains(legendStr,num2str(node))
            legendStr{end+1} = num2str(node);
        end
    end
end

hold off
axis equal
legend(L,legendStr,'location','best','fontsize',lg_font_size);
grid on
xlabel('x [m]')
ylabel('y [m]')
title([event(1).tag.name ' : ' num2str(length(event)) ' contacts'])

%% figure for contacts in z

subplot(4,3,[2 5])
hold on
for nz = 1:num_events
    plot([0 1 ],[tx_z(nz) rx_z(nz)],'-','color',[alpha_grey 5.*alpha_color],'linewidth',7)
end

% plot by rx node
rxc = numel(unique_tag_rx)+1;
for utr = unique_tag_rx
    rxc = rxc -1;
    index = find(tag_rx == utr);
    rx_place = ones(size(index)) + 0.1 * (numel(unique_tag_rx) - rxc);
    scatter(rx_place,rx_z(index),250,marker_color{utr},marker_shape{utr},'filled');
end

% plot by tx node
txc = 0;
for utt = unique_tag_tx
    txc = txc + 1;
    index = find(tag_tx == utt);
    tx_place = zeros(size(index)) - 0.1 * (numel(unique_tag_tx) - txc);
    scatter(tx_place,tx_z(index),250,marker_color{utt},marker_shape{utt},'filled')
end

grid on
ylabel('z [m]');
xticks([0 1])
xticklabels({'tx','rx'})
title([event(1).tag.tstr ' to ' event(end).tag.tstr]);
xlim([-0.4 1.4])
ylim([-100 0])
yticks([-90 -30 -20 0]);

%% figure: data range vs owtt
subplot(5,3,[12 15]);

% plot by rx node
plot([0 10],[0 10.*med_gvel],'-','color',[0.3 0.3 0.3 0.3])
hold on
for utr = unique_tag_rx
    index = find(tag_rx == utr);
    scatter(data_owtt(index),data_range(index),100,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',0.2)
end
hold off
grid on
title('in-situ data: range vs owtt')
set_xy_bounds(data_owtt,sim_owtt,data_range,sim_range);
ylabel('range [m]')
xlabel('owtt [s]')

%% figure: prediction range vs owtt
subplot(5,3,[11 14])
plot([0 10],[0 10.*med_gvel],'-','color',[0.3 0.3 0.3 0.3])
hold on
for utr = unique_tag_rx
    index = find(tag_rx == utr);
    scatter(sim_owtt(index),sim_range(index),100,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',0.1)
end
hold off
grid on
title('in-situ prediction: range vs owtt')
ylabel('range [m]')
xlabel('owtt [s]')
set_xy_bounds(data_owtt, sim_owtt,data_range,sim_range);

%% figure: gvel -- timeline
subplot(5,3,[10 13])
hold on
for utr = unique_tag_rx
    index = find(tag_rx == utr);
    scatter(sim_time(index),sim_gvel(index),100,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',0.3,'handlevisibility','off')
end
hline(med_gvel,'color',[0.3 0.3 0.3 0.3]);
hold off
title('predicted \nu')
ylabel('group velocity [m/s]')
xlabel('time [hr:mm]')
grid on
datetick('x');
set_xy_bounds(sim_time,sim_time,sim_gvel,sim_gvel);
legend('median group velocity','fontsize',lg_font_size,'location','best')

%% figure: owtt -- timeline
subplot(4,3,3)
hold on
for utr = unique_tag_rx
    index = find(tag_rx == utr);
    scatter(data_time(index),data_owtt(index),100,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',0.3)
end
hold off
datetick('x');
grid on
title('in-situ data: owtt')
ylabel('[s]')
set_xy_bounds(data_time,sim_time,data_owtt,sim_owtt)

subplot(4,3,6)
hold on
for utr = unique_tag_rx
    index = find(tag_rx == utr);
    scatter(sim_time(index),sim_owtt(index),100,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',0.3)
end
hold off
datetick('x');
grid on
title('in-situ prediction: owtt')
ylabel('[s]')
set_xy_bounds(data_time,sim_time,data_owtt,sim_owtt)

%% helper function : set_xy_bounds(x1,x2);
function [] = set_xy_bounds(x1,x2,y1,y2)

x_std = std([x1(:); x2(:)]);
y_std = std([y1(:); y2(:)]);

min_xval = min([min(x1(:)) min(x2(:))])-x_std/5;
max_xval = max([max(x1(:)) max(x2(:))])+x_std/5;

min_yval = min([min(y1(:)) min(y2(:))])-y_std/5;
max_yval = max([max(y1(:)) max(y2(:))])+y_std/5;

xlim([min_xval max_xval]);
ylim([min_yval max_yval]);
end