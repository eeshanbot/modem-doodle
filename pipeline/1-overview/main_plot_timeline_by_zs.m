%% main_plot_Timeline_by_zs.m

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
load '../../data/tobytest-recap-clean.mat'
RECAP = h_unpack_experiment(event);

figure('Name','timeline-by-zs','Renderer', 'painters', 'Position', [10 10 1200 650]); clf;
ha = tight_subplot(3,1,.1,[.1 .1],[.1 .1]);

filter_txz = unique(RECAP.tx_z);
filter_rxz = unique(RECAP.rx_z);
filter_node = {'North','South','East','West','Camp'};

count = 0;
for fTNX = filter_txz
    count = count + 1;
    axes(ha(count));
    
    index_tx = RECAP.tx_z == fTNX;
    for fRNX = filter_node
        index_rxn = strcmp(RECAP.tag_rx,fRNX{1});
        
        for fRXZ = filter_rxz
            index_rxz = RECAP.rx_z == fRXZ;
            index_manual_time_filter = RECAP.data_owtt <= 4;
            
            index = logical(index_tx .* index_rxn .* index_rxz .* index_manual_time_filter);
            
            hold on
            scatter(RECAP.data_time(index),RECAP.data_owtt(index),...
                markerSize,markerModemMap(fRNX{1}),markerShape(fRXZ),'filled','MarkerFaceAlpha',0.4)
            hold off
        end
    end
    xlim([min(RECAP.data_time) max(RECAP.data_time)]);
    datetick('x');
    grid on
    yticklabels auto
    ylabel('owtt [s]');
    
    if count ~= 3
        xticklabels([]);
    end
    title(sprintf('zs=%u m',fTNX));
    ybounds = ylim();
    h_plot_patch(RECAP.eof_bool,RECAP.data_time,[-.02 0]);
    ylim(ybounds);
end

xlabel('time [hh:mm]');

%% export
% h_printThesisPNG('timeline-by-zs.png')
