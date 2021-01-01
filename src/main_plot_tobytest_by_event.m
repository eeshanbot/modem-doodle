%% main_plot_tobytest_by_event
% explore data by each toby test
% see notes for time divisions

% eeshan bhatt

%% prep workspace
clear; clc;

lg_font_size = 13;
marker_size = 200;
alpha_grey      = [0.6 0.6 0.6];
alpha_color     = 0.05;

set(0,'defaultAxesFontSize',13)

%% load toby test data by event
location = '../data/data-tobytest-by-event/*.mat';
listing = dir(location);
num_listing = numel(listing);

%%  pick a toby test event!
for iNL = 1:num_listing
    
    figure(iNL); clf;
    
    % load event
    load([listing(iNL).folder '/' listing(iNL).name]);
    
    % one way travel time data
    data_owtt = h_get_nested_val_filter(event,'tag','owtt');
    
    % gps data to range
    tx_x    = h_get_nested_val_filter(event,'tx','x');
    tx_y    = h_get_nested_val_filter(event,'tx','y');
    tx_z    = h_get_nested_val_filter(event,'tx','depth');
    
    rx_x    = h_get_nested_val_filter(event,'rx','x');
    rx_y    = h_get_nested_val_filter(event,'rx','y');
    rx_z    = h_get_nested_val_filter(event,'rx','depth');
    
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
    
    % get tx/rx tags
    tag_tx          = h_get_nested_val_filter(event,'tag','src',filter);
    unique_tag_tx   = sort(unique(tag_tx));
    tag_rx          = h_get_nested_val_filter(event,'tag','rec',filter);
    unique_tag_rx   = sort(unique(tag_rx));
    exp_modem_id    = union(unique_tag_rx,unique_tag_tx);
    
    % useful information
    num_events      = sum(filter);
    
    % sound speed estimate
    toby_test_eof_bool = [1 1 0 1 1 0 0 0 1];
    
    eof_bool = toby_test_eof_bool(iNL);
    
    if eof_bool
        disp('toby test has eof ON')
    else
        disp('toby test has eof OFF');
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
    subplot(6,3,[2 5]);
    hold on
    for nx = 1:num_events
        plot([rx_x(nx) tx_x(nx)],[rx_y(nx) tx_y(nx)],'color',[alpha_grey alpha_color],'linewidth',7,'HandleVisibility','off');
    end
    
    % plot by rx/tx node
    legendStr = {};
    legendCount = 0;
    clear L;
    for node = exp_modem_id
        
        legendCount = legendCount + 1;
        
        itx = find(tag_tx == node);
        if ~isempty(itx)
            L(legendCount) = scatter(tx_x(itx),tx_y(itx),marker_size,marker_color{node},marker_shape{node},'filled');
            legendStr{end+1} = num2str(node);
        end
        
        irx = find(tag_rx == node);
        if ~isempty(irx)
            L(legendCount) = scatter(rx_x(irx),rx_y(irx),marker_size,marker_color{node},marker_shape{node},'filled');
            if ~contains(legendStr,num2str(node))
                legendStr{end+1} = num2str(node);
            end
        end
        
        
    end
    
    L(legendCount+1) = scatter(tx_x,tx_y,marker_size.*1.8,'ro');
    legendStr{end+1} = 'tx';
    
    hold off
    legend(L,legendStr,'location','best','fontsize',lg_font_size);
    grid on
    xlabel('x [m]')
    ylabel('y [m]')
    title([event(1).tag.tstr ' to ' event(end).tag.tstr],'fontsize',lg_font_size+1);
    
    %% figure for contacts in z
    
    subplot(6,3,[1 4])
    hold on
    for nz = 1:num_events
        plot([0 1 ],[tx_z(nz) rx_z(nz)],'-','color',[alpha_grey alpha_color],'linewidth',7)
    end
    
    % plot by rx node
    rxc = numel(unique_tag_rx)+1;
    for utr = unique_tag_rx
        rxc = rxc -1;
        index = find(tag_rx == utr);
        rx_place = ones(size(index)) + 0.1 * (numel(unique_tag_rx) - rxc);
        scatter(rx_place,rx_z(index),marker_size,marker_color{utr},marker_shape{utr},'filled');
        
        unique_rx_z_index = unique(rx_z(index));
        for urzi = unique_rx_z_index
            nContacts = sum(rx_z(index) == urzi);
            if urzi == 30
                buffer = 6;
            else
                buffer = -6;
            end
            text(rx_place(1),urzi + buffer, num2str(nContacts),'HorizontalAlignment','center');
        end
    end
    
    % plot by tx node
    txc = 0;
    for utt = unique_tag_tx
        txc = txc + 1;
        index = find(tag_tx == utt);
        tx_place = zeros(size(index)) - 0.1 * (numel(unique_tag_tx) - txc);
        scatter(tx_place,tx_z(index),marker_size,marker_color{utt},marker_shape{utt},'filled')
        
        unique_tx_z_index = unique(tx_z(index));
        for utzi = unique_tx_z_index
            nContacts = sum(tx_z(index) == utzi);
            if utzi == 30
                buffer = 6;
            else
                buffer = -6;
            end
            text(tx_place(1),utzi + buffer, num2str(nContacts),'HorizontalAlignment','center');
        end
    end
    
    grid on
    ylabel('z [m]');
    xticks([0 1])
    xticklabels({'tx','rx'})
    xlim([-0.4 1.4])
    ylim([0 100])
    set(gca,'ydir','reverse')
    yticks([0 20 30 90]);
    title([event(1).tag.name ' : ' num2str(length(event)) ' contacts'])
    
    %% figure: gvel -- timeline
    subplot(6,3,[3 6])
    hold on
    for utr = unique_tag_rx
        index = find(tag_rx == utr);
        scatter(sim_time(index),sim_gvel(index),marker_size,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',4*alpha_color,'handlevisibility','off')
    end
    hline(med_gvel,'color',[0.3 0.3 0.3 0.3]);
    hold off
    title(['predicted \nu, EOF = ' num2str(eof_bool)],'fontsize',lg_font_size+1)
    ylabel('group velocity [m/s]')
    grid on
    datetick('x');
    h_set_xy_bounds(sim_time,sim_time,sim_gvel,sim_gvel);
    
    %% figure: data owtt -- timeline
    subplot(12,3,[18 24])
    hold on
    for utr = unique_tag_rx
        index = find(tag_rx == utr);
        scatter(data_time(index),data_owtt(index),marker_size,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',4*alpha_color)
    end
    hold off
    datetick('x');
    grid on
    title('in-situ data: owtt','fontsize',lg_font_size+1)
    ylabel('[s]')
    h_set_xy_bounds(data_time,sim_time,data_owtt,sim_owtt)
    
    %% figure : sim owtt -- timeline
    subplot(12,3,[30 36])
    hold on
    for utr = unique_tag_rx
        index = find(tag_rx == utr);
        scatter(sim_time(index),sim_owtt(index),marker_size,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',4*alpha_color)
    end
    hold off
    datetick('x');
    grid on
    title('in-situ prediction: owtt','fontsize',lg_font_size+1)
    ylabel('[s]')
    h_set_xy_bounds(data_time,sim_time,data_owtt,sim_owtt)
    xlabel('time [hr:mm]');
    
    %% figure: data range vs owtt
    subplot(12,3,[17 23]);
    
    % plot by rx node
    plot([0 10],[0 10.*med_gvel],'-','color',[0.3 0.3 0.3 0.3])
    hold on
    for utr = unique_tag_rx
        index = find(tag_rx == utr);
        scatter(data_owtt(index),data_range(index),marker_size,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',alpha_color)
    end
    hold off
    grid on
    title('in-situ data: range vs owtt','fontsize',lg_font_size+1)
    h_set_xy_bounds(data_owtt,sim_owtt,data_range,sim_range);
    ylabel('range [m]')
    str = sprintf('median group velocity = %3.1f m/s',med_gvel);
    legend(str,'fontsize',lg_font_size-1,'location','best')
    
    
    %% figure: prediction range vs owtt
    subplot(12,3,[29 35])
    plot([0 10],[0 10.*med_gvel],'-','color',[0.3 0.3 0.3 0.3])
    hold on
    for utr = unique_tag_rx
        index = find(tag_rx == utr);
        scatter(sim_owtt(index),sim_range(index),marker_size,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',alpha_color)
    end
    hold off
    grid on
    title('in-situ prediction: range vs owtt','fontsize',lg_font_size+1)
    ylabel('range [m]')
    xlabel('owtt [s]')
    h_set_xy_bounds(data_owtt, sim_owtt,data_range,sim_range);
    
    
    
    %% figure : unity comparisons
    subplot(12,3,[16 22])
    plot([0 10],[0 10],':','color',alpha_grey);
    hold on
    for utr = unique_tag_rx
        index = find(tag_rx == utr);
        scatter(data_owtt(index),sim_owtt(index),marker_size,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',alpha_color)
    end
    hold off
    h_set_xy_bounds(data_owtt,sim_owtt,data_owtt,sim_owtt);
    grid on
    xlabel('data owtt [s]')
    ylabel('predicted owtt [s]')
    title('owtt comparison');
    
    subplot(12,3,[28 34])
    plot([0 4000],[0 4000],':','color',alpha_grey);
    hold on
    for utr = unique_tag_rx
        index = find(tag_rx == utr);
        scatter(data_range(index),sim_range(index),marker_size,marker_color{utr},marker_shape{utr},'filled','MarkerFaceAlpha',alpha_color)
    end
    hold off
    h_set_xy_bounds(data_range,sim_range,data_range,sim_range);
    grid on
    xlabel('data range [m]')
    ylabel('predicted range [m]')
    title('range comparison')
    
    %% export plot
    filename = ['dashboard-' event(1).tag.name];
    filename = strrep(filename,' ','-');
    filename = strrep(filename,'.','-');
    export_fig(filename, '-pdf','-png')
    
end