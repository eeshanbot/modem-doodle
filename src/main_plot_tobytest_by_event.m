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
    % load events
    load([listing(iNL).folder '/' listing(iNL).name]);
    
    %% figure 1 : range
    tx_x = get_nested_val(event,'tx','x');
    tx_y = get_nested_val(event,'tx','y');
    tx_z = get_nested_val(event,'tx','z');
    tx_loc = [tx_x; tx_y; tx_z];
    
    rx_x = get_nested_val(event,'rx','x');
    rx_y = get_nested_val(event,'rx','y');
    rx_z = get_nested_val(event,'rx','z');
    rx_loc = [rx_x; rx_y; rx_z];
    
    range = get_nested_val(event,'sim','range');
    
    D = norm(tx_loc - rx_loc);
    
    
    plot(D,range,'.');
    grid on
    xlabel('GPS derived distance');
    ylabel('simulation derived distance');
    
    
    
    
    
end


%% helper function : get_nested_val();
% get a nested value as an array over all structs
function [array] = get_nested_val(obj,lvl1,lvl2)
stuff = [obj.(lvl1)];
array = [stuff.(lvl2)];
end