%% main_plot_gvel_range

%% prep workspace
clear; clc; close all;

lg_font_size = 14;

% easily distinguishable colors to link modems
load p_modemMarkerDetails

%% load toby test data recap all
load '../data/tobytest-recap-clean.mat'
RECAP = h_unpack_experiment(event);

filter_rxz = unique(RECAP.rx_z);
filter_node = {'North','South','East','West','Camp'};

figure('Name','range-gvel-all','Renderer', 'painters', 'Position', [0 0 1280 720]); clf;

%% figure

subplot(1,2,1)
hold on
%scatter(RECAP.sim_range,RECAP.sim_gvel,'o');
for fRNX = filter_node
    index_rxn = strcmp(RECAP.tag_rx,fRNX{1});
        
        for fRXZ = filter_rxz
            index_rxz = RECAP.rx_z == fRXZ;
            
            index = boolean(index_rxn .* index_rxz);
            
            scatter(RECAP.sim_range(index),RECAP.sim_gvel(index),...
                    markerSize,markerModemMap(fRNX{1}),markerShape(fRXZ),'filled','MarkerFaceAlpha',.05)
        end
end
hold off
grid on
h_set_xy_bounds(RECAP.sim_range,RECAP.data_range,RECAP.sim_gvel,RECAP.data_range ./ RECAP.data_owtt);
title('in situ prediction')
ylabel('group velocity [m/s]');
xlabel('range [m]')


subplot(1,2,2)
hold on
%scatter(RECAP.data_range,RECAP.data_range ./ RECAP.data_owtt,'o')
for fRNX = filter_node
    index_rxn = strcmp(RECAP.tag_rx,fRNX{1});
        
        for fRXZ = filter_rxz
            index_rxz = RECAP.rx_z == fRXZ;
            
            index = boolean(index_rxn .* index_rxz);
            
            scatter(RECAP.data_range(index),RECAP.data_range(index) ./ RECAP.data_owtt(index),...
                    markerSize,markerModemMap(fRNX{1}),markerShape(fRXZ),'filled','MarkerFaceAlpha',.05)
        end
end
hold off
grid on
h_set_xy_bounds(RECAP.sim_range,RECAP.data_range,RECAP.sim_gvel,RECAP.data_range ./ RECAP.data_owtt);
title('post processing data')
xlabel('range [m]')



