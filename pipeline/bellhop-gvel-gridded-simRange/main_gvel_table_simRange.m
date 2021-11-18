%% main_gvel_table_simRange.m

%% prep workspace
clear; clc; close all;

%% load toby test data recap all
addpath('../');

load '../../data/tobytest-recap-clean.mat'
RECAP = h_unpack_experiment(event);

% filters :
filter_txz = unique(RECAP.tx_z);
filter_rxz = unique(RECAP.rx_z);
filter_node = {'North','South','East','West','Camp'};

for k = 1:numel(RECAP.tx_z)
    % for ray tracing
    gveltable(k).sourceDepth = RECAP.tx_z(k);
    gveltable(k).recDepth = RECAP.rx_z(k);
    gveltable(k).recRange = RECAP.sim_range(k);
    
    % useful to put in for comparison afterwards
    gveltable(k).simGvel = RECAP.sim_gvel(k);
    gveltable(k).txNode = RECAP.tag_tx{k};
    gveltable(k).rxNode = RECAP.tag_rx{k};
    gveltable(k).owtt = RECAP.data_owtt(k);
end

T = struct2table(gveltable);

writetable(T,'gveltable.csv');