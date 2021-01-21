%% main_plot_gvel_range

%% prep workspace
clear; clc; close all;

lg_font_size = 14;

% easily distinguishable colors to link modems
load p_modemMarkerDetails

%% load toby test data recap all
load '../data/tobytest-recap-clean.mat'
RECAP = h_unpack_experiment(event);

figure('Name','range-gvel-all','Renderer', 'painters', 'Position', [0 0 1280 720]); clf;
hold on

%% figure

subplot(1,2,1)
scatter(RECAP.sim_range,RECAP.sim_gvel,'o');
grid on
h_set_xy_bounds(RECAP.sim_range,RECAP.data_range,RECAP.sim_gvel,RECAP.data_range ./ RECAP.data_owtt);
title('in situ prediction')
ylabel('group velocity [m/s]');
xlabel('range [m]')


subplot(1,2,2)
scatter(RECAP.data_range,RECAP.data_range ./ RECAP.data_owtt,'o')
grid on
h_set_xy_bounds(RECAP.sim_range,RECAP.data_range,RECAP.sim_gvel,RECAP.data_range ./ RECAP.data_owtt);
title('post processing from data')
xlabel('range [m]')



