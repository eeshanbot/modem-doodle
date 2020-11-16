%% play_group_velocity_data.m

clear; clc;

% eeshan bhatt

dir_toby_test = '~/.dropboxmit/icex_2020_mat/toby_test_sorted/';
dir_group_velocity = '~/.dropboxmit/icex_ipynb/gvels_by_node.mat';

%% load group velocity data
load(dir_group_velocity);
gvels_topside = gvels_by_node.hydrohole;
gvels_macrura = gvels_by_node.macrura;

%% 
