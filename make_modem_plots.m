%% make_modem_plots.m

%% prep workspace
clear; clc;

%% load stuff
load('~/.dropboxmit/icex_2020_mat/nav_all.mat')
load('~/.dropboxmit/icex_2020_mat/filtered_all_comms_data.mat')

% get time ranges for TOBY TEST
time_bound(1) = nav_all.toby_test.time(1);
time_bound(2) = nav_all.toby_test.time(end);
d = datetime(time_bound,'ConvertFrom','posixtime'); disp(d);

%% assemble modem data
macrura = comms_sets.macrura_10k;   % modem ID = 4
h1 = comms_sets.h1;                 % modem ID = 10
h2 = comms_sets.h2;                 % modem ID = 11
h3 = comms_sets.h3;                 % modem ID = 12
h4 = comms_sets.h4;                 % modem ID = 13

modem_id_list = [4 10 11 12 13];

[ttXsrc.h1] = sort_comms_data(h1,modem_id_list,time_bound);
[ttXsrc.h2] = sort_comms_data(h2,modem_id_list,time_bound);
[ttXsrc.h3] = sort_comms_data(h3,modem_id_list,time_bound);
[ttXsrc.h4] = sort_comms_data(h4,modem_id_list,time_bound);
[ttXsrc.macrura] = sort_comms_data(macrura,modem_id_list,time_bound);

%% plot?

colorset = colororder();
colorset = colorset(1:numel(modem_id_list),:);

figure(1); clf;

subplot(2,2,1)
plot_comms_data(ttXsrc.h1,colorset,modem_id_list);

subplot(2,2,2)
plot_comms_data(ttXsrc.h2,colorset,modem_id_list);

subplot(2,2,3)
plot_comms_data(ttXsrc.h3,colorset,modem_id_list);

subplot(2,2,4)
plot_comms_data(ttXsrc.h4,colorset,modem_id_list);





%% helper function : sort_comms_data
function [ttXsrc] = sort_comms_data(modem,srcIDs,time_bound);

% filter for time range
% filter by receiving ID only

% initialize matrix for travel_time_by_srcID
ttXsrc = cell(numel(srcIDs),1);

for mm = 1:length(modem.event)
    % check for toby test time stamp
    timestamp = modem.event{mm}.arr_time;
    if (timestamp > time_bound(1) & timestamp < time_bound(2))
        
        % check for srcID and assign
        srcIDmatch = find(double(modem.event{mm}.src) == srcIDs);
        if ~isempty(srcIDmatch)
            ttXsrc{srcIDmatch}(end+1) = modem.event{mm}.travel_time;
        end
    end
end
end

%% helper function : plot_data
function [] = plot_comms_data(ttXsrcXmodem,colorset,modem_id_list)

lgd_count = 0;
for mm = 1:numel(ttXsrcXmodem)
    
    if numel(ttXsrcXmodem{mm}) > 0
        
        lgd_count = lgd_count + 1;
        lgd_str{lgd_count} = num2str(modem_id_list(mm));
        
        [f,x] = ksdensity(ttXsrcXmodem{mm},'bandwidth',0.05);
    
        hold on
        plot(x,f,'-','color',colorset(mm,:),'linewidth',2)
    else
        title(['modem ID = ' num2str(modem_id_list(mm))]);
    end

end
lgd = legend(lgd_str);
title(lgd,'srcID');
hold off
grid on

ylabel('pdf');
xlabel('travel time [s]')
xlim([0 5]);
end