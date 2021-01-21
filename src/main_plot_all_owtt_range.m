%% main_plot_all_owtt_range

%% prep workspace
clear; clc; close all;

lg_font_size = 14;
alpha_color  = .035;

% easily distinguishable colors to link modems
load p_modemMarkerDetails
markerSize = 145;

% legend information
load p_legendDetails

%% load toby test data recap all
load '../data/tobytest-recap-clean.mat'
RECAP = h_unpack_experiment(event);

figure('Name','owtt-range-all','Renderer', 'painters', 'Position', [10 10 1700 1100]); clf;
hold on

filter_txz = unique(RECAP.tx_z);
filter_rxz = unique(RECAP.rx_z);
filter_node = {'North','South','East','West','Camp'};

for fRNX = filter_node
    index_rxn = strcmp(RECAP.tag_rx,fRNX{1});
        
        for fRXZ = filter_txz
            index_rxz = RECAP.rx_z == fRXZ;
            
            index = boolean(index_rxn .* index_rxz);
            
            scatter(RECAP.data_owtt(index),RECAP.data_range(index),...
                    markerSize,markerModemMap(fRNX{1}),markerShape(fRXZ),'filled','MarkerFaceAlpha',0.2)
        end
end

grid on
xlabel('owtt [s]')
ylabel('range [m]');
