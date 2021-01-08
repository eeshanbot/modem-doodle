%% main_sort_tobytest_by_design

%% prep workspace
clear; clc;

%% load all event data
load('./tobytest-recap-clean.mat');

addpath('../');

%% filters

tx_depth = h_get_nested_val_filter(event,'tx','depth');
eeof_bool = h_get_nested_val_filter(event,'tag','eeof');

% unique tx, eeof_bool
unique_tx_depth = sort(unique(tx_depth));
unique_eeof_bool = sort(unique(eeof_bool));

%% loop through data

for utd = unique_tx_depth
    for ute = unique_eeof_bool
        
        index_depth = tx_depth == utd;
        index_eeof  = eeof_bool == ute;
        index = and(index_depth,index_eeof);
        
        str = sprintf('tobytest-txz%d-eeof%d',utd,ute);
        
        experiment = event(index);
        save(str,'experiment');
    end
end