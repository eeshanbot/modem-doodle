%% main_sort_tobytest_by_design

%% prep workspace
clear; clc;

%% load all event data
load('../../data/tobytest-recap-clean-v2.mat');

%% filters

tx_depth = h_unpack_val(event,'tx','depth');
eeof_bool = h_unpack_val(event,'tag','eeof');
owtt = h_unpack_val(event,'tag','owtt');
index_owtt = owtt <= 4;

% unique tx, eeof_bool
unique_tx_depth = sort(unique(tx_depth));
unique_eeof_bool = sort(unique(eeof_bool));

%% loop through data

for utd = unique_tx_depth
    for ute = unique_eeof_bool
        
        index_depth = tx_depth == utd;
        index_eeof  = eeof_bool == ute;
        
        index = boolean(index_depth .* index_eeof .* index_owtt);
        
        str = sprintf('tobytest-txz%d-eeof%d',utd,ute);
        
        experiment = event(index);
        save(str,'experiment');
    end
end

%% helper function : h_unpack_val
function [array] = h_unpack_val(obj,lvl1,lvl2)
stuff = [obj.(lvl1)];
array = [stuff.(lvl2)];
end